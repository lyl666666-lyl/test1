/**
 * @file HandleRefereeSignal.h
 *
 * This file defines an option that handles the detection of referee signals
 * in the standby state and during kick-ins. A robot only tries to look at
 * the referee if it stands inside a ring segment surrounding the referee
 * position, when a state starts that requires detecting a referee signal.
 * The detection stops when any robot on the team detects an expeced
 * referee signal, a timeout is reached, or the state ends. In case of a
 * kick-in, the robot will turn in the direction of the referee if just
 * turning the head is not sufficient.
 *
 * @author Thomas Röfer
 */

#include "SkillBehaviorControl.h"

/**
 * The detection of the referee signal. It only becomes active if the robot is
 * in the right place.
 */
option((SkillBehaviorControl) HandleRefereeSignal,
       defs((float)(2800.f) upperImageBorderAtHeight, /**< The height to look at (in mm). */
            (float)(2000.f) upperImageBorderAtHeightStandby, /**< The height to look at in standby (in mm). */
            (float)(515.f) assumedCameraHeight, /**< The assumed height of the camera above ground (in mm). */
            (Rangef)({1500.f, 8000.f}) distanceRange, /**< The distance range for this option to become active during kick-in. */
            (Rangea)({15_deg, 165_deg}) bearingRange, /**< The bearing range to the referee for this option to become active. */
            (int)(12000) kickInWaitTime, /**< How long to unsuccessfully look at referee during kick-in. */
            (Angle)(60_deg) maxHeadTurn, /**< Maximum head rotation before the body has to be turned. */
            (Angle)(2_deg) turnTolerance, /**< Accepted tolerance when reaching the required body rotation. */
            (int)(3000) searchStartTime, /**< Time to wait before starting head search if no signal detected (in ms). */
            (float)(1000.f) searchHeightLow, /**< Lower height to search at (in mm). */
            (float)(3500.f) searchHeightHigh, /**< Upper height to search at (in mm). */
            (int)(2000) searchCycleDuration, /**< Duration of one complete search cycle (in ms). */
            (int)(1000) confirmationTime)) /**< Time to confirm signal detection before accepting it (in ms). */
       vars((unsigned)(0) searchStartTimestamp, /**< Timestamp when search should start. */
            (float)(0.f) confirmedLookAtHeight)) /**< Height at which signal was first detected for confirmation. */
{
  const Vector2f refereeOnField(theFieldDimensions.xPosHalfwayLine,
                                (theFieldDimensions.yPosLeftTouchline + theFieldDimensions.yPosLeftFieldBorder) / 2.f
                                * (theGameState.leftHandTeam ? 1 : -1));
  const Vector2f refereeOffsetOnField = refereeOnField - theRobotPose.translation;
  const Vector2f refereeOffsetRelative = theRobotPose.inverse() * refereeOnField;
  const float refereeDistance = refereeOffsetOnField.norm();

  // This assumes that both cameras have roughly the same opening angles.
  const float lookAtHeight = std::tan(std::atan2((theGameState.state == GameState::standby || theGameState.state == GameState::beforeHalf ||
                                                  theGameState.state == GameState::timeout
                                                  ? upperImageBorderAtHeightStandby : upperImageBorderAtHeight)
                                                 - assumedCameraHeight, refereeDistance)
                                      - theCameraInfo.openingAngleHeight * 0.5f) * refereeDistance + assumedCameraHeight;

  const auto refereeSignalDetected = [&](const RefereeSignal::Signal signal)
  {
    if(theRefereeSignal.signal == signal && theRefereeSignal.timeWhenDetected >= theGameState.timeWhenStateStarted)
      return true;
    else
      for(const Teammate& teammate : theTeamData.teammates)
        if(teammate.theRefereeSignal.signal == signal && teammate.theRefereeSignal.timeWhenDetected >= theGameState.timeWhenStateStarted)
          return true;
    return false;
  };

  common_transition
  {
    if((theGameState.state != GameState::standby && theGameState.state != GameState::beforeHalf && theGameState.state != GameState::timeout && !theGameState.isKickIn())
       || (theGameState.state == GameState::standby && refereeSignalDetected(RefereeSignal::ready))
       || (theGameState.isKickIn() && (theStrategyStatus.role == ActiveRole::toRole(ActiveRole::freeKickWall)
                                       || theFrameInfo.getTimeSince(theGameState.timeWhenStateStarted) > kickInWaitTime
                                       || refereeSignalDetected(RefereeSignal::kickInLeft)
                                       || refereeSignalDetected(RefereeSignal::kickInRight))))
      goto inactive;
  }

  initial_state(inactive)
  {
    transition
    {
      DEBUG_RESPONSE_ONCE("option:HandleRefereeSignal:now")
        goto turnToReferee;
      if(theGameState.gameControllerActive && bearingRange.isInside(std::abs(refereeOffsetOnField.angle())))
      {
        if(theGameState.state == GameState::standby || theGameState.state == GameState::beforeHalf || theGameState.state == GameState::timeout)
          goto lookAtReferee;
        else if(!theGameState.kickingTeamKnown && theGameState.isKickIn() && distanceRange.isInside(refereeDistance))
          goto turnToReferee;
      }
    }
  }

  state(turnToReferee)
  {
    transition
    {
      if(std::abs(refereeOffsetRelative.angle()) < maxHeadTurn)
        goto lookAtReferee;
    }
    action
    {
      const Angle lookDir = Rangea(-maxHeadTurn, maxHeadTurn).clamped(refereeOffsetRelative.angle());
      const Vector2f lookOffset = Pose2f(lookDir) * Vector2f(refereeOffsetRelative.norm(), 0.f);
      LookAtPoint({.target = {lookOffset.x(), lookOffset.y(), lookAtHeight},
                   .camera = HeadMotionRequest::upperCamera});
      const Angle rotationDiff = refereeOffsetRelative.angle();
      WalkToPose({.target = {std::max(0.f, std::abs(rotationDiff) - maxHeadTurn + turnTolerance) * sgn(rotationDiff)}});
    }
  }

  state(lookAtReferee)
  {
    transition
    {
      // 如果在standby状态下等待一段时间后仍未检测到裁判手势，则开始搜索
      if((theGameState.state == GameState::standby || theGameState.state == GameState::beforeHalf || theGameState.state == GameState::timeout)
         && searchStartTimestamp != 0
         && theFrameInfo.getTimeSince(searchStartTimestamp) > searchStartTime
         && !refereeSignalDetected(RefereeSignal::ready))
        goto searchForReferee;
    }
    action
    {
      // 记录开始时间戳
      if(state_time == 0)
        searchStartTimestamp = theFrameInfo.time;
      
      LookAtPoint({.target = {refereeOffsetRelative.x(), refereeOffsetRelative.y(), lookAtHeight},
                   .camera = HeadMotionRequest::upperCamera});
      Stand({.high = (theGameState.state == GameState::standby || theGameState.state == GameState::beforeHalf || theGameState.state ==
                      GameState::timeout)});
      theRefereeDetectionRequest.detectReferee = true;
    }
  }

  state(searchForReferee)
  {
    transition
    {
      // 如果在搜索过程中检测到裁判手势，进入确认状态
      if(theRefereeSignal.signal == RefereeSignal::ready && theRefereeSignal.timeWhenDetected >= theGameState.timeWhenStateStarted)
        goto confirmSignal;
      
      // 如果队友已经确认检测到手势，直接返回正常状态
      if(refereeSignalDetected(RefereeSignal::ready))
      {
        searchStartTimestamp = theFrameInfo.time;
        goto lookAtReferee;
      }
    }
    action
    {
      // 计算搜索周期内的当前位置（上下移动）
      const int timeSinceSearchStart = theFrameInfo.getTimeSince(searchStartTimestamp) - searchStartTime;
      const int cycleTime = timeSinceSearchStart % searchCycleDuration;
      const float cycleProgress = static_cast<float>(cycleTime) / searchCycleDuration;
      
      // 使用正弦波实现平滑的上下移动：0 -> 高 -> 低 -> 高 -> 0
      const float searchHeight = searchHeightLow + (searchHeightHigh - searchHeightLow) * 
                                 (0.5f + 0.5f * std::sin(cycleProgress * 2.f * pi - pi / 2.f));
      
      const float searchLookAtHeight = std::tan(std::atan2(searchHeight - assumedCameraHeight, refereeDistance)
                                               - theCameraInfo.openingAngleHeight * 0.5f) * refereeDistance + assumedCameraHeight;
      
      LookAtPoint({.target = {refereeOffsetRelative.x(), refereeOffsetRelative.y(), searchLookAtHeight},
                   .camera = HeadMotionRequest::upperCamera});
      Stand({.high = true});
      theRefereeDetectionRequest.detectReferee = true;
    }
  }

  state(confirmSignal)
  {
    transition
    {
      // 如果确认时间足够，返回正常观察状态（此时信号已被记录并会自动传递给队友）
      if(state_time > confirmationTime)
      {
        searchStartTimestamp = theFrameInfo.time;
        goto lookAtReferee;
      }
      
      // 如果在确认期间信号丢失，返回搜索状态
      if(theRefereeSignal.signal != RefereeSignal::ready)
        goto searchForReferee;
    }
    action
    {
      // 记录首次检测到信号时的观察高度
      if(state_time == 0)
      {
        const int timeSinceSearchStart = theFrameInfo.getTimeSince(searchStartTimestamp) - searchStartTime;
        const int cycleTime = timeSinceSearchStart % searchCycleDuration;
        const float cycleProgress = static_cast<float>(cycleTime) / searchCycleDuration;
        const float searchHeight = searchHeightLow + (searchHeightHigh - searchHeightLow) * 
                                   (0.5f + 0.5f * std::sin(cycleProgress * 2.f * pi - pi / 2.f));
        confirmedLookAtHeight = std::tan(std::atan2(searchHeight - assumedCameraHeight, refereeDistance)
                                                    - theCameraInfo.openingAngleHeight * 0.5f) * refereeDistance + assumedCameraHeight;
      }
      
      // 保持头部在检测到信号时的位置，持续观察以确认
      LookAtPoint({.target = {refereeOffsetRelative.x(), refereeOffsetRelative.y(), confirmedLookAtHeight},
                   .camera = HeadMotionRequest::upperCamera});
      Stand({.high = true});
      theRefereeDetectionRequest.detectReferee = true;
    }
  }
}
