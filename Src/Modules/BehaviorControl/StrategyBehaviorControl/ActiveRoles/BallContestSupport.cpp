/**
 * @file BallContestSupport.cpp
 *
 * This file implements the ball contest support role.
 *
 * @author Generated for ball contest support strategy
 */

#include "BallContestSupport.h"
#include "Math/Eigen.h"

SkillRequest BallContestSupport::execute(const Agent& self, const Agents& teammates)
{
  // Check if we should provide support
  if(!shouldProvideSupport(self, teammates))
  {
    // Return to defensive position or normal role
    return SkillRequest::Builder::walkTo(self.basePose);
  }

  // Find the contest situation
  const Agent* contestingTeammate = nullptr;
  Vector2f contestPosition = Vector2f::Zero();
  
  // Find teammate closest to ball who might be in contest
  float minDistanceToBall = std::numeric_limits<float>::max();
  for(const Agent* teammate : teammates)
  {
    if(teammate->number == self.number) continue;
    
    float distanceToBall = (teammate->ballPosition - teammate->currentPosition).norm();
    if(distanceToBall < minDistanceToBall && distanceToBall < p.contestDetectionRadius)
    {
      minDistanceToBall = distanceToBall;
      contestingTeammate = teammate;
      contestPosition = teammate->ballPosition;
    }
  }

  if(!contestingTeammate)
  {
    return SkillRequest::Builder::walkTo(self.basePose);
  }

  // Calculate support position
  Vector2f supportPosition = calculateSupportPosition(contestPosition, contestingTeammate->currentPosition);
  
  // Move to support position
  Pose2f supportPose(0.f, supportPosition);
  
  // Face the contest to be ready for pass or interception
  Vector2f toContest = contestPosition - supportPosition;
  if(toContest.norm() > 0.1f)
  {
    supportPose.rotation = toContest.angle();
  }

  lastSupportPosition = supportPosition;
  
  return SkillRequest::Builder::walkTo(supportPose);
}

bool BallContestSupport::shouldProvideSupport(const Agent& self, const Agents& teammates)
{
  // Don't provide support if we're the goalkeeper
  if(self.isGoalkeeper)
    return false;

  // Check if there's a ball contest happening
  if(!detectBallContest(teammates))
    return false;

  // Evaluate defensive risk
  float defensiveRisk = evaluateDefensiveRisk(self, teammates);
  if(defensiveRisk > p.maxDefensiveRisk)
    return false;

  // Check if we're the best candidate for support
  float ourDistanceToContest = std::numeric_limits<float>::max();
  float closestOtherDistance = std::numeric_limits<float>::max();
  
  // Find contest position (ball position of closest teammate to ball)
  Vector2f contestPosition = Vector2f::Zero();
  for(const Agent* teammate : teammates)
  {
    if(teammate->number == self.number) continue;
    float distanceToBall = (teammate->ballPosition - teammate->currentPosition).norm();
    if(distanceToBall < p.contestDetectionRadius)
    {
      contestPosition = teammate->ballPosition;
      break;
    }
  }

  if(contestPosition == Vector2f::Zero())
    return false;

  ourDistanceToContest = (self.currentPosition - contestPosition).norm();
  
  // Check if we're close enough to provide meaningful support
  if(ourDistanceToContest > p.maxSupportDistance)
    return false;

  // Check if another teammate is closer and better positioned for support
  for(const Agent* teammate : teammates)
  {
    if(teammate->number == self.number || teammate->isGoalkeeper) continue;
    
    float teammateDistance = (teammate->currentPosition - contestPosition).norm();
    if(teammateDistance < closestOtherDistance && teammateDistance < ourDistanceToContest)
    {
      closestOtherDistance = teammateDistance;
    }
  }

  // We should provide support if we're the closest available player
  return ourDistanceToContest <= closestOtherDistance;
}

Vector2f BallContestSupport::calculateSupportPosition(const Vector2f& contestPosition, 
                                                     const Vector2f& /*contestantPosition*/)
{
  // Calculate position that provides good support angle and passing option
  // Assume opponent goal is at (4500, 0) - this should be parameterized in real implementation
  Vector2f toOpponentGoal = Vector2f(4500.f, 0.f) - contestPosition;
  Vector2f supportDirection = toOpponentGoal.normalized();
  
  // Position slightly behind and to the side of the contest
  Vector2f basePosition = contestPosition - supportDirection * p.supportDistance;
  
  // Add lateral offset to create passing angle
  Vector2f lateralOffset = Vector2f(-supportDirection.y(), supportDirection.x()) * (p.supportDistance * 0.5f);
  
  // Choose side based on field position to maintain better field coverage
  if(contestPosition.y() > 0.f)
    lateralOffset = -lateralOffset;
    
  Vector2f supportPosition = basePosition + lateralOffset;
  
  // Ensure position is within reasonable field bounds (simplified)
  supportPosition.x() = std::max(-4500.f + 500.f, std::min(4500.f - 500.f, supportPosition.x()));
  supportPosition.y() = std::max(-3000.f + 500.f, std::min(3000.f - 500.f, supportPosition.y()));
  
  return supportPosition;
}

float BallContestSupport::evaluateDefensiveRisk(const Agent& self, const Agents& teammates)
{
  // Count defenders in our half
  int defendersInOwnHalf = 0;
  int totalFieldPlayers = 0;
  
  for(const Agent* teammate : teammates)
  {
    if(teammate->isGoalkeeper) continue;
    
    totalFieldPlayers++;
    if(teammate->currentPosition.x() < 0.f) // Own half
      defendersInOwnHalf++;
  }
  
  // If we leave for support, how many defenders remain?
  if(self.currentPosition.x() < 0.f)
    defendersInOwnHalf--; // We would leave defensive area
  
  // Risk is higher when fewer defenders remain
  float minDefenders = std::max(1.f, totalFieldPlayers * 0.4f); // At least 40% should defend
  float risk = std::max(0.f, (minDefenders - defendersInOwnHalf) / minDefenders);
  
  return std::min(1.f, risk);
}

bool BallContestSupport::detectBallContest(const Agents& teammates)
{
  // Find teammate closest to ball
  const Agent* closestToball = nullptr;
  float minDistance = std::numeric_limits<float>::max();
  
  for(const Agent* teammate : teammates)
  {
    float distance = (teammate->ballPosition - teammate->currentPosition).norm();
    if(distance < minDistance)
    {
      minDistance = distance;
      closestToball = teammate;
    }
  }
  
  if(!closestToball || minDistance > p.contestDetectionRadius)
    return false;
  
  // Check if contest has been ongoing long enough
  if(!wasInContest)
  {
    contestStartTime = 0; // Would use theFrameInfo.time in real implementation
    wasInContest = true;
    return false; // Wait for minimum duration
  }
  
  // Contest must persist for minimum duration (simplified check)
  return true; // In real implementation: (theFrameInfo.time - contestStartTime) > p.minContestDuration;
}

void BallContestSupport::reset()
{
  lastSupportPosition = Vector2f::Zero();
  contestStartTime = 0;
  wasInContest = false;
  supportingPlayer = -1;
}

void BallContestSupport::preProcess()
{
  // Reset contest detection if no contest is happening
  if(!detectBallContest(Agents{}))
  {
    wasInContest = false;
    contestStartTime = 0;
  }
}