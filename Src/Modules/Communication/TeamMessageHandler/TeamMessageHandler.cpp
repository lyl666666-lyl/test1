/**
 * @file TeamMessageHandler.cpp
 *
 * Implements a module that both sends and receives team messages.
 * It ensures that less messages are sent than are allowed. It also checks whether
 * the data that would be sent is significantly different from the data that was last
 * sent. Otherwise, sending the message is skipped.
 *
 * @author Jesse Richter-Klug
 * @author Thomas Röfer
 */

#include "TeamMessageHandler.h"
#include "Representations/Communication/TeamData.h"
#include "Debugging/Annotation.h"
#include "Debugging/Plot.h"
#include "Framework/Settings.h"
#include "Platform/File.h"
#include "Platform/SystemCall.h"
#include "Platform/Time.h"
#include "Streaming/Global.h"
#include <algorithm>
#include <sys/stat.h>

//#define SITTING_TEST
//#define SELF_TEST

MAKE_MODULE(TeamMessageHandler);

// GameControllerRBS and RobotPose cannot be part of this for technical reasons.
#define FOREACH_TEAM_MESSAGE_REPRESENTATION(_) \
  _(RobotStatus); \
  _(FrameInfo); \
  _(BallModel); \
  _(Whistle); \
  _(BehaviorStatus); \
  _(StrategyStatus); \
  _(IndirectKick); \
  _(RefereeSignal);

struct TeamMessage
{};

void TeamMessageHandler::regTeamMessage()
{
  PUBLISH(regTeamMessage);
  const char* name = typeid(TeamMessage).name();
  TypeRegistry::addClass(name, nullptr);
#define REGISTER_TEAM_MESSAGE_REPRESENTATION(x) \
  TypeRegistry::addAttribute(name, (std::string(#x) == "Whistle" ? typeid(WhistleCompact) : typeid(x)).name(), "the" #x)

  TypeRegistry::addAttribute(name, typeid(RobotPoseCompact).name(), "theRobotPose");
  FOREACH_TEAM_MESSAGE_REPRESENTATION(REGISTER_TEAM_MESSAGE_REPRESENTATION);
}

TeamMessageHandler::TeamMessageHandler() :
  theTeamMessageChannel(inTeamMessage, outTeamMessage),
  theGameControllerRBS(theFrameInfo, theGameControllerData)
{
  File f("teamMessage.def", "r");
  ASSERT(f.exists());
  std::string source(f.getSize(), 0);
  f.read(source.data(), source.length());
  teamCommunicationTypeRegistry.addTypes(source);
  teamCommunicationTypeRegistry.compile();
  teamMessageType = teamCommunicationTypeRegistry.getTypeByName("TeamMessage");
#ifndef TARGET_ROBOT
  theTeamMessageChannel.startLocal(Settings::getPortForTeam(Global::getSettings().teamNumber), static_cast<unsigned>(Global::getSettings().playerNumber));
#else
  theTeamMessageChannel.start(Settings::getPortForTeam(Global::getSettings().teamNumber));
#endif

  // Initialize team communication log with timestamp
  auto now = std::chrono::system_clock::now();
  auto time = std::chrono::system_clock::to_time_t(now);
  std::tm* tm = std::localtime(&time);
  
  // Create match folder with timestamp: YYYYMMDD_HHMMSS
  std::stringstream matchFolder;
  matchFolder << std::put_time(tm, "%Y%m%d_%H%M%S");
  
  std::string teamFolder = "Team" + std::to_string(Global::getSettings().teamNumber);
  std::string logDir;
  
#ifdef TARGET_ROBOT
  // On real robot, write to a shared location that can be accessed from dev machine
  // Try to use NFS mount first, fallback to local if not available
  std::string nfsLogDir = "/mnt/dev_logs/" + matchFolder.str() + "/" + teamFolder + "/";
  std::string localLogDir = std::string(File::getBHDir()) + "/logs/" + matchFolder.str() + "/" + teamFolder + "/";
  
  // Check if NFS mount exists
  struct stat st;
  if(stat("/mnt/dev_logs", &st) == 0 && S_ISDIR(st.st_mode))
  {
    logDir = nfsLogDir;
    OUTPUT_TEXT("Using NFS mounted log directory: " << logDir);
  }
  else
  {
    logDir = localLogDir;
    OUTPUT_TEXT("NFS not available, using local log directory: " << logDir);
  }
#else
  // In simulator, use Config/Sim_Logs directory
  logDir = std::string(File::getBHDir()) + "/Config/Sim_Logs/" + matchFolder.str() + "/" + teamFolder + "/";
#endif
  
  // Create directory if not exists (using standard library)
  try
  {
    std::filesystem::create_directories(logDir);
  }
  catch(const std::exception& e)
  {
    OUTPUT_ERROR("Failed to create log directory: " << logDir << " - " << e.what());
#ifdef TARGET_ROBOT
    // Fallback to local directory
    logDir = std::string(File::getBHDir()) + "/logs/" + matchFolder.str() + "/" + teamFolder + "/";
    std::filesystem::create_directories(logDir);
#endif
  }
  
  std::stringstream logName;
  logName << logDir << "team_comm_p" << Global::getSettings().playerNumber << ".txt";
  teamCommLogFile.open(logName.str(), std::ios::out);
  if(teamCommLogFile.is_open())
  {
    teamCommLogFile << "========================================\n";
    teamCommLogFile << "团队通信日志\n";
    teamCommLogFile << "比赛时间: " << std::put_time(tm, "%Y-%m-%d %H:%M:%S") << "\n";
    teamCommLogFile << "队伍编号: " << Global::getSettings().teamNumber << "\n";
    teamCommLogFile << "机器人编号: " << Global::getSettings().playerNumber << "\n";
    teamCommLogFile << "机器人名称: " << Global::getSettings().bodyName << "\n";
    teamCommLogFile << "日志路径: " << logName.str() << "\n";
    teamCommLogFile << "========================================\n\n";
    teamCommLogFile.flush();
    OUTPUT_TEXT("TeamComm log file created: " << logName.str());
    
    // HTML visualization generation disabled
    // std::string htmlPath = logDir + "view_logs.html";
    // std::ifstream checkHtml(htmlPath);
    // if(!checkHtml.good())
    // {
    //   generateVisualizationHTML(logDir, teamFolder);
    //   OUTPUT_TEXT("Generated visualization HTML: " << htmlPath);
    // }
  }
  else
  {
    OUTPUT_ERROR("Failed to create TeamComm log file: " << logName.str());
  }
}

void TeamMessageHandler::update(BHumanMessageOutputGenerator& outputGenerator)
{
  DECLARE_PLOT("module:TeamMessageHandler:messageLength");
  DECLARE_PLOT("module:TeamMessageHandler:budgetLimit");
  DECLARE_DEBUG_RESPONSE("module:TeamMessageHandler:statistics");
  MODIFY("module:TeamMessageHandler:statistics", statistics);

  DEBUG_RESPONSE("module:TeamMessageHandler:budgetLimit")
  {
    const int remainingTime = TeamMessageHandler::remainingTime(0);
    const float ratio = Rangef::ZeroOneRange().limit(remainingTime / ((durationOfHalf + maxOvertime) * 2.f));

    PLOT("module:TeamMessageHandler:budgetLimit", overallMessageBudget * ratio + normalMessageReserve * (1.f - ratio));
  }

  PLOT("module:TeamMessageHandler:previewMessageBudget", ownModeledBudget);

  DEBUG_RESPONSE_ONCE("module:TeamMessageHandler:generateTCMPluginClass")
    teamCommunicationTypeRegistry.generateTCMPluginClass("BHumanMessage.java", static_cast<const CompressedTeamCommunication::RecordType*>(teamMessageType));

  wasPenalized |= theExtendedGameState.wasPenalized() && theExtendedGameState.returnFromGameControllerPenalty && (theGameState.isPlaying() || theGameState.isReady() || theGameState.isSet());

  // Set RobotPose to position, which other teammates are probably assuming
  if(theGameState.isSet() && theExtendedGameState.wasReady())
  {
    auto it = std::find_if(theAgentStates.agents.begin(), theAgentStates.agents.end(), [&](const Agent& agent) {return agent.number == theGameState.playerNumber; });
    if(it != theAgentStates.agents.end())
    {
      lastSent.theRobotPose.translation = it->basePose.translation;
      lastSent.theBehaviorStatus.walkingTo = Vector2f::Zero();
      lastSent.theBehaviorStatus.speed = 0.f;
    }
  }

  // Update ball constraint to send based on differences between the own ball and the team ball
  const Vector2f ballEndPosition = BallPhysics::getEndPosition(theBallModel.estimate.position,
                                   theBallModel.estimate.velocity,
                                   theBallSpecification.friction);
  const Vector2f teamBallEndPosition = theRobotPose.inverse() * BallPhysics::getEndPosition(theTeamBallModel.position,
                                       theTeamBallModel.velocity,
                                       theBallSpecification.friction);

  if(!globalBearingsChanged(theRobotPose, ballEndPosition, theRobotPose, teamBallEndPosition, mapToRange(ballEndPosition.norm(), teamBallDistanceInterpolationRange.min, teamBallDistanceInterpolationRange.max, positionThreshold, teamBallMaxPositionThreshold)))
    timeWhenBallWasNearTeamBall = theFrameInfo.time;

  outputGenerator.sendThisFrame = [this]
  {
    bool alwaysSend = this->alwaysSend;
    DEBUG_RESPONSE("module:TeamMessageHandler:alwaysSend")
      alwaysSend = true;
    const bool stateAllowsSending = notInPlayDead() && !theGameState.isPenaltyShootout() && !theGameState.isPenalized() && allowCommunicationAfterPenalty();
    const bool alwaysSendAllowed = alwaysSend && enoughTimePassed();
    const bool alwaysSendPlaying = alwaysSendInPlaying && enoughTimePassed() && theGameState.isPlaying() && withinPriorityBudget();
    const bool signalDetectedSend = refereeSignalDetected() && withinPriorityBudget();
    const bool returnFromPenalty = returnFromPenaltyRobotPoseCommunication();
    const bool whistleDetectedSend = (theGameState.isReady() || theGameState.isSet() || theGameState.isPlaying()) && withinPriorityBudget() && whistleDetected();
    const bool indirectKickChangedSend = theGameState.isPlaying() && withinPriorityBudget() && indirectKickChanged();
    const bool canSendPriorityMessage = stateAllowsSending && (alwaysSendAllowed || alwaysSendPlaying || signalDetectedSend || whistleDetectedSend || indirectKickChangedSend || returnFromPenalty);
    const bool normalChangeDetected = stateAllowsSending && enoughTimePassed() && theGameState.isPlaying() && robotPoseValid() && withinOverallBudget() &&
    (behaviorStatusChanged() || robotStatusChanged() || strategyStatusChanged() || robotPoseChanged() || ballModelChanged() || teamBallOld());

    if(!canSendPriorityMessage && !normalChangeDetected)
      setTimeDelay();

    return canSendPriorityMessage || (normalChangeDetected && checkTimeDelay());
  };

  // Make sure we can not exceed 615 messages in first half and 30 messages in second half
  ASSERT(!withinSlowedBudget() || ownModeledBudget > (theGameState.phase == GameState::firstHalf ? overallMessageBudget - (overallMessageBudget - normalMessageReserve) / 2.f : normalMessageReserve));

  theRobotStatus.isUpright = (theFallDownState.state == FallDownState::upright || theFallDownState.state == FallDownState::staggering || theFallDownState.state == FallDownState::squatting) &&
                             (theGroundContactState.contact && theMotionInfo.executedPhase != MotionPhase::getUp && theMotionInfo.executedPhase != MotionPhase::fall);
  if(theRobotStatus.isUpright)
    theRobotStatus.timeWhenLastUpright = theFrameInfo.time;

  outputGenerator.send = [this, &outputGenerator]()
  {
    if(!writeMessage(outputGenerator, &outTeamMessage))
      return;
    wasPenalized = false;
    theTeamMessageChannel.send();
    setTimeDelay();
    ownModeledBudget -= std::min(ownModeledBudget, 1u);

    // Plot length of message:
    PLOT("module:TeamMessageHandler:messageLength", outTeamMessage.length);
    
    // Log to file with full context (thread-safe)
    if(teamCommLogFile.is_open())
    {
      std::lock_guard<std::mutex> lock(logFileMutex);
      teamCommLogFile << "\n[发送] 时间=" << theFrameInfo.time << "ms\n";
      teamCommLogFile << "  机器人: " << static_cast<int>(theGameState.playerNumber) << "号\n";
      teamCommLogFile << "  位置: (" << static_cast<int>(theRobotPose.translation.x()) << ", " 
                      << static_cast<int>(theRobotPose.translation.y()) << ") 朝向=" << theRobotPose.rotation << "\n";
      teamCommLogFile << "  球: (" << static_cast<int>(theBallModel.estimate.position.x()) << ", " 
                      << static_cast<int>(theBallModel.estimate.position.y()) << ") 可见度=" 
                      << static_cast<int>(theBallModel.seenPercentage) << "%\n";
      teamCommLogFile << "  角色: " << TypeRegistry::getEnumName(theStrategyStatus.role) << "\n";
      teamCommLogFile << "  传球目标: " << theBehaviorStatus.passTarget << " | 行走目标: (" 
                      << static_cast<int>(theBehaviorStatus.walkingTo.x()) << "," 
                      << static_cast<int>(theBehaviorStatus.walkingTo.y()) << ")\n";
      teamCommLogFile << "  机器人状态: " << TypeRegistry::getEnumName(theFallDownState.state);
      if(theFallDownState.direction != FallDownState::none)
        teamCommLogFile << " (方向: " << TypeRegistry::getEnumName(theFallDownState.direction) << ")";
      teamCommLogFile << "\n";
      teamCommLogFile << "  裁判手势: " << TypeRegistry::getEnumName(theRefereeSignal.signal) << "\n";
      teamCommLogFile << "  消息预算剩余: " << ownModeledBudget << "\n";
      teamCommLogFile.flush();
    }
  };
}

bool TeamMessageHandler::writeMessage(BHumanMessageOutputGenerator& outputGenerator, TeamMessageChannel::Container* const m)
{
#define SEND_PARTICLE(particle) \
  the##particle >> outputGenerator

  outputGenerator.playerNumber = static_cast<uint8_t>(theGameState.playerNumber);

  outputGenerator.timestamp = theFrameInfo.time;

  outputGenerator.compressedContainer.reserve(sizeof(m->data));
  CompressedTeamCommunicationOut stream(outputGenerator.compressedContainer, outputGenerator.timestamp,
                                        teamMessageType, !outputGenerator.sentMessages);
  outputGenerator.out = &stream;

  SEND_PARTICLE(GameControllerRBS);

  if(sendMirroredRobotPose)
  {
    RobotPose theMirroredRobotPose = theRobotPose;
    theMirroredRobotPose.translation *= -1.f;
    theMirroredRobotPose.rotation = Angle::normalize(theMirroredRobotPose.rotation + pi);
    SEND_PARTICLE(MirroredRobotPose);
  }
  else
    SEND_PARTICLE(RobotPose);

  FOREACH_TEAM_MESSAGE_REPRESENTATION(SEND_PARTICLE);

  outputGenerator.playerNumber |= theRobotHealth.maxJointTemperatureStatus << 4;

  outputGenerator.out = nullptr;

  if(outputGenerator.sizeOfBHumanMessage() > sizeof(m->data))
  {
    OUTPUT_ERROR("BHumanMessage too big (" <<
                 static_cast<unsigned>(outputGenerator.sizeOfBHumanMessage()) <<
                 " > " << static_cast<unsigned>(sizeof(m->data)) << ")");
    return false;
  }

  static_cast<const BHumanMessage&>(outputGenerator).write(reinterpret_cast<void*>(m->data));
  m->length = static_cast<uint8_t>(outputGenerator.sizeOfBHumanMessage());

  DEBUG_RESPONSE("module:TeamMessageHandler:statistics")
  {
#define COUNT(name) \
  statistics.count(#name, the##name != lastSent.the##name)

    COUNT(RobotStatus.isUpright);
    // COUNT(BehaviorStatus.calibrationFinished);
    COUNT(BehaviorStatus.passTarget);
    statistics.count("BehaviorStatus.shootingTo",
                     globalBearingsChanged(theRobotPose, theBehaviorStatus.shootingTo,
                                           lastSent.theRobotPose, lastSent.theBehaviorStatus.shootingTo));
    COUNT(StrategyStatus.proposedTactic);
    //COUNT(StrategyStatus.acceptedTactic);
    COUNT(StrategyStatus.proposedMirror);
    COUNT(StrategyStatus.acceptedMirror);
    COUNT(StrategyStatus.proposedSetPlay);
    //COUNT(StrategyStatus.acceptedSetPlay);
    //COUNT(StrategyStatus.setPlayStep);
    COUNT(StrategyStatus.position);
    COUNT(StrategyStatus.role);
    statistics.count("RobotPose.translation", robotPoseChanged());
    statistics.count("GlobalBallEndPosition", ballModelChanged());
    statistics.count("TeamBallOld", teamBallOld());
  }

  outputGenerator.sentMessages++;
  timeWhenLastSent = theFrameInfo.time;
  backup(outputGenerator);

  return true;
}

void TeamMessageHandler::update(ReceivedTeamMessages& receivedTeamMessages)
{
  // Reset representation (should contain only data from current frame).
  receivedTeamMessages.messages.clear();
  receivedTeamMessages.unsynchronizedMessages = 0;

  // Prepare timestamp conversion by updating the GameController packet buffer.
  theGameControllerRBS.update();

  while(theTeamMessageChannel.receive())
  {
    if(readTeamMessage(&inTeamMessage))
    {
      theGameControllerRBS << receivedMessageContainer;

      // Don't accept messages from robots to which we do not know a time offset yet.
      if(dropUnsynchronizedMessages && !theGameControllerRBS[receivedMessageContainer.playerNumber]->isValid())
      {
        ANNOTATION("TeamMessageHandler", "Got unsynchronized message from " << receivedMessageContainer.playerNumber << ".");
        ++receivedTeamMessages.unsynchronizedMessages;
        continue;
      }

      lastReceivedTimestamps[receivedMessageContainer.playerNumber - Settings::lowestValidPlayerNumber] = receivedMessageContainer.timestamp;

      receivedTeamMessages.messages.emplace_back();
      parseMessage(receivedTeamMessages.messages.back());
      
      // Log received message to file (thread-safe)
      if(teamCommLogFile.is_open())
      {
        std::lock_guard<std::mutex> lock(logFileMutex);
        const auto& msg = receivedTeamMessages.messages.back();
        teamCommLogFile << "\n[接收] 时间=" << theFrameInfo.time << "ms 来自机器人" << static_cast<int>(msg.number) << "号\n";
        teamCommLogFile << "  位置: (" << static_cast<int>(msg.theRobotPose.translation.x()) << ", " 
                        << static_cast<int>(msg.theRobotPose.translation.y()) << ") 朝向=" << msg.theRobotPose.rotation << "\n";
        teamCommLogFile << "  球: (" << static_cast<int>(msg.theBallModel.estimate.position.x()) << ", " 
                        << static_cast<int>(msg.theBallModel.estimate.position.y()) << ") 可见度=" 
                        << static_cast<int>(msg.theBallModel.seenPercentage) << "%\n";
        teamCommLogFile << "  角色: " << TypeRegistry::getEnumName(msg.theStrategyStatus.role) << "\n";
        teamCommLogFile << "  传球目标: " << msg.theBehaviorStatus.passTarget << " | 行走目标: (" 
                        << static_cast<int>(msg.theBehaviorStatus.walkingTo.x()) << "," 
                        << static_cast<int>(msg.theBehaviorStatus.walkingTo.y()) << ")\n";
        teamCommLogFile << "  机器人状态: " << (msg.theRobotStatus.isUpright ? "站立" : "倒地") << "\n";
        teamCommLogFile << "  裁判手势: " << TypeRegistry::getEnumName(msg.theRefereeSignal.signal) << "\n";
        teamCommLogFile.flush();
      }
      
      continue;
    }

    if(receivedMessageContainer.lastErrorCode == ReceivedBHumanMessage::myOwnMessage
#ifndef NDEBUG
       || receivedMessageContainer.lastErrorCode == ReceivedBHumanMessage::magicNumberDidNotMatch
#endif
       || receivedMessageContainer.lastErrorCode == ReceivedBHumanMessage::duplicate
      ) continue;

    // the message had a parsing error
    if(theFrameInfo.getTimeSince(timeWhenLastMimimi) > minTimeBetween2RejectSounds && SystemCall::playSound("intruderAlert.wav"))
      timeWhenLastMimimi = theFrameInfo.time;

    ANNOTATION("intruder-alert", "error code: " << receivedMessageContainer.lastErrorCode);
  };

  handleBudgetPreview(receivedTeamMessages);
}

void TeamMessageHandler::handleBudgetPreview(ReceivedTeamMessages& receivedTeamMessages)
{
  if(theGameState.ownTeam.messageBudget != lastReceivedBudget || !receivedTeamMessages.messages.empty())
    timeWhenLastTeamSent = theFrameInfo.time;

  // Budget update from GameController
  if(theGameState.ownTeam.messageBudget != lastReceivedBudget)
  {
    // Reset own model
    lastReceivedBudget = ownModeledBudget = theGameState.ownTeam.messageBudget;
    // All messages until this moment, including messages in this frame, are assumed to be received by the GC too
  }
  else
    ownModeledBudget -= std::min(ownModeledBudget, static_cast<unsigned>(receivedTeamMessages.messages.size()));
}

bool TeamMessageHandler::readTeamMessage(const TeamMessageChannel::Container* const m)
{
  if(!receivedMessageContainer.read(m->data, m->length))
  {
    receivedMessageContainer.lastErrorCode = ReceivedBHumanMessage::magicNumberDidNotMatch;
    return false;
  }

  receivedMessageContainer.playerNumber &= 15;

#ifndef SELF_TEST
  if(receivedMessageContainer.playerNumber == theGameState.playerNumber)
  {
    receivedMessageContainer.lastErrorCode = ReceivedBHumanMessage::myOwnMessage;
    return false;
  }
#endif // !SELF_TEST

  if(receivedMessageContainer.playerNumber < Settings::lowestValidPlayerNumber ||
     receivedMessageContainer.playerNumber > Settings::highestValidPlayerNumber)
  {
    receivedMessageContainer.lastErrorCode = ReceivedBHumanMessage::invalidPlayerNumber;
    return false;
  }

  // Duplicate messages actually exist (cf. RoboCup German Open 2024). In that case, they arrived
  // immediately after each other, but not necessarily in the same frame. It is unclear whether,
  // if multiple messages are sent within a short timespan, those can overtake each other (such that
  // at the receiving robot, the sequence looks like A B A B instead of A A B B).
  const unsigned lastTimestamp = lastReceivedTimestamps[receivedMessageContainer.playerNumber - Settings::lowestValidPlayerNumber];
  if(receivedMessageContainer.timestamp == lastTimestamp)
  {
    receivedMessageContainer.lastErrorCode = ReceivedBHumanMessage::duplicate;
    return false;
  }

  return true;
}

#define RECEIVE_PARTICLE(particle) teamMessage.the##particle << receivedMessageContainer
void TeamMessageHandler::parseMessage(ReceivedTeamMessage& teamMessage)
{
  teamMessage.number = receivedMessageContainer.playerNumber;

  CompressedTeamCommunicationIn stream(receivedMessageContainer.compressedContainer,
                                       receivedMessageContainer.timestamp, teamMessageType,
                                       [smb = theGameControllerRBS[teamMessage.number]](unsigned u) { return smb->getRemoteTimeInLocalTime(u); });
  receivedMessageContainer.in = &stream;

  RECEIVE_PARTICLE(RobotPose);
  FOREACH_TEAM_MESSAGE_REPRESENTATION(RECEIVE_PARTICLE);

  receivedMessageContainer.in = nullptr;
}

#define BACKUP_PARTICLE(particle) lastSent.the##particle << receivedMessageContainer
void TeamMessageHandler::backup(const BHumanMessageOutputGenerator& outputGenerator)
{
  CompressedTeamCommunicationIn stream(outputGenerator.compressedContainer, outputGenerator.timestamp, teamMessageType,
                                       [](unsigned u) { return u; });
  receivedMessageContainer.in = &stream;

  BACKUP_PARTICLE(RobotPose);
  FOREACH_TEAM_MESSAGE_REPRESENTATION(BACKUP_PARTICLE);

  receivedMessageContainer.in = nullptr;
}

bool TeamMessageHandler::globalBearingsChanged(const RobotPose& origin, const std::optional<Vector2f>& offset,
                                               const RobotPose& oldOrigin, const std::optional<Vector2f>& oldOffset) const
{
  if(!offset.has_value() || !oldOffset.has_value())
    return offset.has_value(); // Changed only if zero -> not zero
  else
    return globalBearingsChanged(origin, offset.value(), oldOrigin, oldOffset.value());
}

bool TeamMessageHandler::globalBearingsChanged(const RobotPose& origin, const Vector2f& offset,
                                               const RobotPose& oldOrigin, const Vector2f& oldOffset,
                                               const std::optional<float>& positionalThreshold) const
{
  const float usedPositionThreshold = positionalThreshold.has_value() ? positionalThreshold.value() : positionThreshold;
  const Vector2f oldOffsetInCurrent = origin.inverse() * (oldOrigin * oldOffset);
  const Angle distanceAngle = Vector2f(offset.norm(), assumedObservationHeight).angle();
  const Angle oldDistanceAngle = Vector2f(oldOffsetInCurrent.norm(), assumedObservationHeight).angle();
  return ((offset - oldOffsetInCurrent).squaredNorm() > sqr(usedPositionThreshold) &&
          (offset.isZero() || oldOffsetInCurrent.isZero() ||
           offset.angleTo(oldOffsetInCurrent) > bearingThreshold ||
           std::abs(Angle::normalize(distanceAngle - oldDistanceAngle)) > bearingThreshold));
}

bool TeamMessageHandler::teammateBearingsChanged(const Vector2f& position, const Vector2f& oldPosition) const
{
  for(const Teammate& teammate : theTeamData.teammates)
  {
    const Vector2f estimatedPosition = Teammate::getEstimatedPosition(teammate.theRobotPose,
                                                                      teammate.theBehaviorStatus.walkingTo,
                                                                      teammate.theBehaviorStatus.speed,
                                                                      theFrameInfo.getTimeSince(teammate.theFrameInfo.time));
    const Vector2f offset = position - estimatedPosition;
    const Vector2f oldOffset = oldPosition - estimatedPosition;
    const Angle distanceAngle = Vector2f(offset.norm(), assumedObservationHeight).angle();
    const Angle oldDistanceAngle = Vector2f(oldOffset.norm(), assumedObservationHeight).angle();
    if((offset - oldOffset).squaredNorm() > sqr(positionThreshold) &&
       (offset.isZero() || oldOffset.isZero() ||
        offset.angleTo(oldOffset) > bearingThreshold ||
        std::abs(Angle::normalize(distanceAngle - oldDistanceAngle)) > bearingThreshold))
      return true;
  }
  return false;
}

bool TeamMessageHandler::enoughTimePassed() const
{
  return theFrameInfo.getTimeSince(timeWhenLastSent) >= minSendInterval || theFrameInfo.time < timeWhenLastSent;
}

bool TeamMessageHandler::notInPlayDead() const
{
#if !defined SITTING_TEST && defined TARGET_ROBOT
  return theMotionRequest.motion != MotionRequest::playDead &&
         theMotionInfo.executedPhase != MotionPhase::playDead;
#else
  return true;
#endif
}

bool TeamMessageHandler::checkTimeDelay() const
{
  // When switching to striker, sending is allowed without delay
  // Otherwise wait 0.6 to 1.2 seconds to allow other robots to send important information
  // TODO determine better parameters
  // TODO 600 ms min delay, because we currently do not have a preview of the message budget.
  // If we have -> could go down to 200 ms? But max should remain at 1200 ms?
  return theFrameInfo.getTimeSince(timeWhenLastSendTryStarted) >
         (Role::isActiveRole(theStrategyStatus.role) && !Role::isActiveRole(lastSent.theStrategyStatus.role) ?
          sendDelayPlayBall :
          mapToRange(static_cast<int>(theFieldBall.recentBallPositionRelative().norm()), ballDistanceRangeForDelay.min, ballDistanceRangeForDelay.max, sendDelayRange.min, sendDelayRange.max));
}

float TeamMessageHandler::calcTeamSendInterval() const
{
  const int trueMessageBudget = (overallMessageBudget - normalMessageReserve);
  const unsigned messageBudgetLimitThisHalf = theGameState.phase == GameState::firstHalf ? overallMessageBudget - trueMessageBudget / 2 : normalMessageReserve;
  const float messageFactor = (durationOfHalf + maxOvertime) * 2.f / trueMessageBudget;
  const float minTeamSendInterval = minTeamSendIntervalFactor * messageFactor;
  const float timeLeftInHalf = TeamMessageHandler::remainingTime(0) - (theGameState.phase == GameState::firstHalf ? durationOfHalf + maxOvertime : 0.f);
  const float minMessageSendInterval = ownModeledBudget > messageBudgetLimitThisHalf ? timeLeftInHalf / (ownModeledBudget - messageBudgetLimitThisHalf) : std::numeric_limits<float>::max();
  const float scalingWaittime = minTeamSendIntervalFactor * messageFactor * (calcCurrentBudgetLimit(theFrameInfo.getTimeSince(timeWhenLastTeamSent)) - ownModeledBudget) / reduceBudgetMalusTime;
  // If within budget, just return minTeamSendInterval
  // Otherwise return the max rate of
  // - the configured one,
  // - the rate to reach the limit within 30sec
  // - the rate at which we can still communicate to not surpass normalMessageReserve
  return withinNormalBudget() ? minTeamSendInterval : std::max({minTeamSendInterval, minMessageSendInterval, scalingWaittime});
}

float TeamMessageHandler::calcCurrentBudgetLimit(const int timeOffset) const
{
  const int remainingTime = TeamMessageHandler::remainingTime(timeOffset);
  const float ratio = Rangef::ZeroOneRange().limit(remainingTime / ((durationOfHalf + maxOvertime) * 2.f));
  return overallMessageBudget * ratio + normalMessageReserve * (1.f - ratio);
}

void TeamMessageHandler::setTimeDelay()
{
  timeWhenLastSendTryStarted = theFrameInfo.time;
}

bool TeamMessageHandler::withinNormalBudget() const
{
  return ownModeledBudget > calcCurrentBudgetLimit(0);
}

bool TeamMessageHandler::withinSlowedBudget() const
{
  return theFrameInfo.getTimeSince(timeWhenLastTeamSent) > calcTeamSendInterval();
}

bool TeamMessageHandler::withinOverallBudget() const
{
  return withinNormalBudget() || withinSlowedBudget();
}

int TeamMessageHandler::remainingTime(const int timeOffset) const
{
  const int timeRemainingInCurrentHalf = std::max(0, -theFrameInfo.getTimeSince(theGameState.timeWhenPhaseEnds) + maxOvertime + timeOffset);
  const int timeInNextHalf = (theGameState.phase == GameState::firstHalf ? durationOfHalf + maxOvertime : 0);
  return std::max(0, timeRemainingInCurrentHalf - lookahead) + timeInNextHalf;
}

bool TeamMessageHandler::withinPriorityBudget() const
{
  return ownModeledBudget > priorityMessageReserve;
}

bool TeamMessageHandler::whistleDetected() const
{
  const int timeRemainingInCurrentHalf = std::max(0, -theFrameInfo.getTimeSince(theGameState.timeWhenPhaseEnds));
  return theWhistle.lastTimeWhistleDetected > lastSent.theWhistle.lastTimeWhistleDetected + minSendInterval &&
         timeRemainingInCurrentHalf >= ignoreWhistleBeforeEndOfHalf &&
         theFrameInfo.getTimeSince(theWhistle.lastTimeWhistleDetected) <= maxWhistleSendDelay;
}

bool TeamMessageHandler::refereeSignalDetected() const
{
  return theFrameInfo.getTimeSince(theRefereeSignal.timeWhenDetected) < maxRefereeSendDelay &&
         theRefereeSignal.timeWhenDetected > lastSent.theRefereeSignal.timeWhenDetected + minSendInterval &&
         // If this robot detected the referee signal, we are already in ready state. We switched because of
         // another robot, the previous state is not standby anymore, so we do not waste a packet.
         ((theExtendedGameState.stateLastFrame == GameState::standby &&
           theRefereeSignal.signal == RefereeSignal::ready &&
           !teammatesDetectedRefereeSignal(RefereeSignal::ready)) ||
          (theGameState.isKickIn() &&
           (theRefereeSignal.signal == RefereeSignal::kickInLeft ||
            theRefereeSignal.signal == RefereeSignal::kickInRight) &&
           !teammatesDetectedRefereeSignal(RefereeSignal::kickInLeft) &&
           !teammatesDetectedRefereeSignal(RefereeSignal::kickInRight)));
}

bool TeamMessageHandler::returnFromPenaltyRobotPoseCommunication() const
{
  return wasPenalized && (theRobotPose.quality != RobotPose::poor || theFrameInfo.getTimeSince(theGameState.timeWhenPlayerStateStarted) > theBehaviorParameters.noSkillRequestAfterUnpenalizedTime);
}

bool TeamMessageHandler::allowCommunicationAfterPenalty() const
{
  return theFrameInfo.getTimeSince(theGameState.timeWhenPlayerStateStarted) > theBehaviorParameters.noCommunicationAfterUnpenalizedTime;
}

bool TeamMessageHandler::teammatesDetectedRefereeSignal(const RefereeSignal::Signal signal) const
{
  for(const Teammate& teammate : theTeamData.teammates)
    if(teammate.theRefereeSignal.signal == signal && teammate.theRefereeSignal.timeWhenDetected >= theGameState.timeWhenStateStarted)
      return true;
  return false;
}

bool TeamMessageHandler::behaviorStatusChanged() const
{
  return (// theBehaviorStatus.calibrationFinished != lastSent.theBehaviorStatus.calibrationFinished || // not used
          theBehaviorStatus.passTarget != lastSent.theBehaviorStatus.passTarget ||
          // theBehaviorStatus.walkingTo != lastSent.behaviorStatus.walkingTo || // included in robotPoseChanged
          // theBehaviorStatus.speed != lastSent.behaviorStatus.speed || // included in robotPoseChanged
          globalBearingsChanged(theRobotPose, theBehaviorStatus.shootingTo, lastSent.theRobotPose, lastSent.theBehaviorStatus.shootingTo));
}

bool TeamMessageHandler::robotStatusChanged() const
{
  return theRobotStatus.isUpright != lastSent.theRobotStatus.isUpright;
}

bool TeamMessageHandler::strategyStatusChanged() const
{
  auto goalKeeperPositionSwitch = [](const Tactic::Position::Type position, const Tactic::Position::Type lastPosition) -> bool
  {
    return Tactic::Position::isGoalkeeper(position) && Tactic::Position::isGoalkeeper(lastPosition);
  };

  auto activeStrikerSwitch = [this](const Role::Type role)
  {
    return role != ActiveRole::toRole(ActiveRole::playBall) ||
           theBallModel.estimate.velocity == Vector2f::Zero();
  };

  return (theStrategyStatus.proposedTactic != lastSent.theStrategyStatus.proposedTactic ||
          // theStrategyStatus.acceptedTactic != lastSent.theStrategyStatus.acceptedTactic ||
          theStrategyStatus.proposedMirror != lastSent.theStrategyStatus.proposedMirror ||
          theStrategyStatus.acceptedMirror != lastSent.theStrategyStatus.acceptedMirror ||
          theStrategyStatus.proposedSetPlay != lastSent.theStrategyStatus.proposedSetPlay ||
          // theStrategyStatus.acceptedSetPlay != lastSent.theStrategyStatus.acceptedSetPlay ||
          // theStrategyStatus.setPlayStep != lastSent.theStrategyStatus.setPlayStep ||
          (theStrategyStatus.position != lastSent.theStrategyStatus.position && !goalKeeperPositionSwitch(theStrategyStatus.position, lastSent.theStrategyStatus.position)) ||
          (theStrategyStatus.role != lastSent.theStrategyStatus.role && activeStrikerSwitch(theStrategyStatus.role)));
}

bool TeamMessageHandler::robotPoseValid() const
{
  return theRobotPose.quality != RobotPose::LocalizationQuality::poor;
}

bool TeamMessageHandler::robotPoseChanged() const
{
  const Vector2f estimatedPosition = Teammate::getEstimatedPosition(lastSent.theRobotPose,
                                                                    lastSent.theBehaviorStatus.walkingTo,
                                                                    lastSent.theBehaviorStatus.speed,
                                                                    theFrameInfo.getTimeSince(lastSent.theFrameInfo.time));
  return ((theRobotPose.translation - estimatedPosition).norm() > positionThreshold &&
          teammateBearingsChanged(theRobotPose.translation, estimatedPosition));
}

bool TeamMessageHandler::ballModelChanged() const
{
  if((theFrameInfo.getTimeSince(theBallModel.timeWhenDisappeared) < disappearedThreshold) !=
     (lastSent.theFrameInfo.getTimeSince(lastSent.theBallModel.timeWhenDisappeared) < disappearedThreshold))
    return true;
  else if(theBallModel.timeWhenLastSeen == lastSent.theBallModel.timeWhenLastSeen)
    return false;
  else
  {
    const Vector2f ballEndPosition = BallPhysics::getEndPosition(theBallModel.estimate.position,
                                                                 theBallModel.estimate.velocity,
                                                                 theBallSpecification.friction);
    const Vector2f oldBallEndPosition = BallPhysics::getEndPosition(lastSent.theBallModel.estimate.position,
                                                                    lastSent.theBallModel.estimate.velocity,
                                                                    theBallSpecification.friction);

    return globalBearingsChanged(theRobotPose, ballEndPosition, lastSent.theRobotPose, oldBallEndPosition) &&
           teammateBearingsChanged(theRobotPose * ballEndPosition, lastSent.theRobotPose * oldBallEndPosition) &&
           (!theTeamBallModel.isValid ||
            theFrameInfo.getTimeSince(timeWhenBallWasNearTeamBall) > minTimeBallIsNotNearTeamBall);
  }
}

bool TeamMessageHandler::teamBallOld() const
{
  // Our ball is old, too
  if(theFrameInfo.getTimeSince(theBallModel.timeWhenLastSeen) > newBallThreshold)
    return false;

  // Determine the latest ball timestamp that was communicated
  const auto newest = std::max_element(theTeamData.teammates.begin(), theTeamData.teammates.end(),
                                       [](const Teammate& t1, const Teammate& t2)
                                       {return t1.theBallModel.timeWhenLastSeen < t2.theBallModel.timeWhenLastSeen;});
  const unsigned timeWhenLastSeen = std::max(newest == theTeamData.teammates.end() ? 0 : newest->theBallModel.timeWhenLastSeen,
                                             lastSent.theBallModel.timeWhenLastSeen);

  return theFrameInfo.getTimeSince(timeWhenLastSeen) > teamBallThresholdBase + theGameState.playerNumber * teamBallThresholdFactor;
}

bool TeamMessageHandler::indirectKickChanged() const
{
  return theIndirectKick.lastKickTimestamp > lastSent.theIndirectKick.lastKickTimestamp && !theIndirectKick.allowDirectKick && lastSent.theIndirectKick.lastKickTimestamp < theIndirectKick.lastSetPlayTime; // lastSetPlayTime checks every GameState change
}

void TeamMessageHandler::generateVisualizationHTML(const std::string& teamDir, const std::string& teamFolder) const
{
  std::string htmlPath = teamDir + "view_logs.html";
  std::ofstream htmlFile(htmlPath);
  
  if(!htmlFile.is_open())
  {
    OUTPUT_ERROR("Failed to create visualization HTML: " << htmlPath);
    return;
  }
  
  htmlFile << R"(<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>)" << teamFolder << R"( - 团队通信日志查看器</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { font-size: 1.1em; opacity: 0.9; }
        .controls {
            padding: 25px;
            background: #f8f9fa;
            border-bottom: 2px solid #e9ecef;
        }
        .control-group { margin-bottom: 15px; }
        .control-group label {
            display: block;
            font-weight: 600;
            margin-bottom: 8px;
            color: #495057;
        }
        .filter-bar {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
        }
        .filter-bar input, .filter-bar select {
            flex: 1;
            min-width: 200px;
            padding: 10px 15px;
            border: 2px solid #dee2e6;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        .filter-bar input:focus, .filter-bar select:focus {
            outline: none;
            border-color: #667eea;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            padding: 25px;
            background: #f8f9fa;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.3s;
        }
        .stat-card:hover { transform: translateY(-5px); }
        .stat-card .value {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 5px;
        }
        .stat-card .label { color: #6c757d; font-size: 0.9em; }
        .content { padding: 25px; }
        .log-entry {
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 15px;
            transition: all 0.3s;
        }
        .log-entry:hover {
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            border-color: #667eea;
        }
        .log-entry.send { border-left: 5px solid #28a745; }
        .log-entry.receive { border-left: 5px solid #007bff; }
        .log-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 1px solid #e9ecef;
        }
        .log-type {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 0.9em;
        }
        .log-type.send { background: #28a745; color: white; }
        .log-type.receive { background: #007bff; color: white; }
        .log-time { color: #6c757d; font-size: 0.9em; }
        .log-details {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        .detail-item {
            background: #f8f9fa;
            padding: 12px;
            border-radius: 8px;
        }
        .detail-item .detail-label {
            font-weight: 600;
            color: #495057;
            margin-bottom: 5px;
            font-size: 0.85em;
        }
        .detail-item .detail-value { color: #212529; font-size: 1em; }
        .no-data {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 )" << teamFolder << R"( 团队通信日志</h1>
            <p>自动加载本队所有机器人日志</p>
        </div>
        
        <div class="controls">
            <div class="control-group">
                <label>🔍 筛选条件</label>
                <div class="filter-bar">
                    <input type="text" id="searchInput" placeholder="搜索关键词...">
                    <select id="typeFilter">
                        <option value="all">全部类型</option>
                        <option value="send">仅发送</option>
                        <option value="receive">仅接收</option>
                    </select>
                    <select id="robotFilter">
                        <option value="all">全部机器人</option>
                    </select>
                </div>
            </div>
        </div>
        
        <div class="stats" id="stats">
            <div class="stat-card">
                <div class="value" id="totalMessages">0</div>
                <div class="label">总消息数</div>
            </div>
            <div class="stat-card">
                <div class="value" id="sendMessages">0</div>
                <div class="label">发送消息</div>
            </div>
            <div class="stat-card">
                <div class="value" id="receiveMessages">0</div>
                <div class="label">接收消息</div>
            </div>
            <div class="stat-card">
                <div class="value" id="robotCount">0</div>
                <div class="label">机器人数量</div>
            </div>
        </div>
        
        <div class="content" id="content">
            <div class="no-data">
                <div style="font-size: 4em; margin-bottom: 20px;">⏳</div>
                <h3>正在加载日志...</h3>
            </div>
        </div>
    </div>

    <script>
        let allLogs = [];
        let filteredLogs = [];

        document.getElementById('searchInput').addEventListener('input', applyFilters);
        document.getElementById('typeFilter').addEventListener('change', applyFilters);
        document.getElementById('robotFilter').addEventListener('change', applyFilters);

        // Auto-load all log files in this directory
        async function loadAllLogs() {
            const logFiles = [
                'team_comm_p1.txt',
                'team_comm_p2.txt',
                'team_comm_p3.txt',
                'team_comm_p4.txt',
                'team_comm_p5.txt'
            ];
            
            for (const filename of logFiles) {
                try {
                    const response = await fetch(filename);
                    if (response.ok) {
                        const content = await response.text();
                        parseLogs(content, filename);
                    }
                } catch (e) {
                    console.log('Could not load ' + filename);
                }
            }
            
            updateRobotFilter();
            applyFilters();
            updateStats();
        }

        function parseLogs(content, filename) {
            const lines = content.split('\n');
            let currentLog = null;
            
            for (let line of lines) {
                line = line.trim();
                
                if (line.startsWith('[发送]') || line.startsWith('[接收]')) {
                    if (currentLog) {
                        allLogs.push(currentLog);
                    }
                    
                    const type = line.startsWith('[发送]') ? 'send' : 'receive';
                    const timeMatch = line.match(/时间=(\d+)ms/);
                    const robotMatch = line.match(/来自机器人(\d+)号/) || line.match(/机器人: (\d+)号/);
                    
                    currentLog = {
                        type: type,
                        time: timeMatch ? parseInt(timeMatch[1]) : 0,
                        robot: robotMatch ? parseInt(robotMatch[1]) : null,
                        filename: filename,
                        details: {}
                    };
                } else if (currentLog && line) {
                    if (line.includes('位置:')) {
                        currentLog.details.position = line.replace('位置:', '').trim();
                    } else if (line.includes('球:')) {
                        currentLog.details.ball = line.replace('球:', '').trim();
                    } else if (line.includes('角色:')) {
                        currentLog.details.role = line.replace('角色:', '').trim();
                    } else if (line.includes('传球目标:')) {
                        currentLog.details.pass = line.replace('传球目标:', '').trim();
                    } else if (line.includes('消息预算剩余:')) {
                        currentLog.details.budget = line.replace('消息预算剩余:', '').trim();
                    }
                }
            }
            
            if (currentLog) {
                allLogs.push(currentLog);
            }
        }

        function updateRobotFilter() {
            const robots = new Set();
            allLogs.forEach(log => {
                if (log.robot) robots.add(log.robot);
            });
            
            const select = document.getElementById('robotFilter');
            select.innerHTML = '<option value="all">全部机器人</option>';
            
            Array.from(robots).sort((a, b) => a - b).forEach(robot => {
                const option = document.createElement('option');
                option.value = robot;
                option.textContent = `机器人 ${robot} 号`;
                select.appendChild(option);
            });
        }

        function applyFilters() {
            const searchTerm = document.getElementById('searchInput').value.toLowerCase();
            const typeFilter = document.getElementById('typeFilter').value;
            const robotFilter = document.getElementById('robotFilter').value;
            
            filteredLogs = allLogs.filter(log => {
                if (typeFilter !== 'all' && log.type !== typeFilter) return false;
                if (robotFilter !== 'all' && log.robot !== parseInt(robotFilter)) return false;
                if (searchTerm) {
                    const searchableText = JSON.stringify(log).toLowerCase();
                    if (!searchableText.includes(searchTerm)) return false;
                }
                return true;
            });
            
            renderLogs();
        }

        function renderLogs() {
            const content = document.getElementById('content');
            
            if (filteredLogs.length === 0) {
                content.innerHTML = `
                    <div class="no-data">
                        <div style="font-size: 4em; margin-bottom: 20px;">🔍</div>
                        <h3>没有找到匹配的日志</h3>
                        <p style="margin-top: 10px;">尝试调整筛选条件</p>
                    </div>
                `;
                return;
            }
            
            content.innerHTML = filteredLogs.map(log => `
                <div class="log-entry ${log.type}">
                    <div class="log-header">
                        <span class="log-type ${log.type}">
                            ${log.type === 'send' ? '📤 发送' : '📥 接收'}
                            ${log.robot ? ` - 机器人 ${log.robot} 号` : ''}
                        </span>
                        <span class="log-time">⏱️ ${log.time}ms</span>
                    </div>
                    <div class="log-details">
                        ${log.details.position ? `
                            <div class="detail-item">
                                <div class="detail-label">📍 位置</div>
                                <div class="detail-value">${log.details.position}</div>
                            </div>
                        ` : ''}
                        ${log.details.ball ? `
                            <div class="detail-item">
                                <div class="detail-label">⚽ 球位置</div>
                                <div class="detail-value">${log.details.ball}</div>
                            </div>
                        ` : ''}
                        ${log.details.role ? `
                            <div class="detail-item">
                                <div class="detail-label">👤 角色</div>
                                <div class="detail-value">${log.details.role}</div>
                            </div>
                        ` : ''}
                        ${log.details.pass ? `
                            <div class="detail-item">
                                <div class="detail-label">🎯 传球/行走</div>
                                <div class="detail-value">${log.details.pass}</div>
                            </div>
                        ` : ''}
                        ${log.details.budget ? `
                            <div class="detail-item">
                                <div class="detail-label">💰 消息预算</div>
                                <div class="detail-value">${log.details.budget}</div>
                            </div>
                        ` : ''}
                    </div>
                </div>
            `).join('');
        }

        function updateStats() {
            const sendCount = allLogs.filter(log => log.type === 'send').length;
            const receiveCount = allLogs.filter(log => log.type === 'receive').length;
            const robots = new Set(allLogs.map(log => log.robot).filter(r => r));
            
            document.getElementById('totalMessages').textContent = allLogs.length;
            document.getElementById('sendMessages').textContent = sendCount;
            document.getElementById('receiveMessages').textContent = receiveCount;
            document.getElementById('robotCount').textContent = robots.size;
        }

        // Start loading logs
        loadAllLogs();
    </script>
</body>
</html>
)";
  
  htmlFile.close();
  OUTPUT_TEXT("Successfully generated visualization HTML at: " << htmlPath);
}
