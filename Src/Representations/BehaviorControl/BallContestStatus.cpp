/**
 * @file BallContestStatus.cpp
 *
 * This file implements the BallContestStatus representation.
 *
 * @author Generated for ball contest support strategy
 */

#include "BallContestStatus.h"
#include "Math/Eigen.h"
#include <algorithm>

void BallContestStatus::update(const Vector2f& ballPosition, 
                               const std::vector<Vector2f>& teammatePositions,
                               const std::vector<Vector2f>& opponentPositions,
                               unsigned currentTime)
{
  lastUpdateTime = currentTime;
  
  // Constants for contest detection
  const float contestDistance = 500.f; // mm - distance to consider players in contest
  const float contestDuration = 2000;  // ms - minimum duration to trigger support
  const float maxDefensiveRisk = 0.7f; // maximum acceptable defensive risk
  
  // Find closest players to ball
  float closestTeammateDistance = std::numeric_limits<float>::max();
  float closestOpponentDistance = std::numeric_limits<float>::max();
  int closestTeammateIndex = -1;
  int closestOpponentIndex = -1;
  
  for(size_t i = 0; i < teammatePositions.size(); ++i)
  {
    float distance = (teammatePositions[i] - ballPosition).norm();
    if(distance < closestTeammateDistance)
    {
      closestTeammateDistance = distance;
      closestTeammateIndex = static_cast<int>(i);
    }
  }
  
  for(size_t i = 0; i < opponentPositions.size(); ++i)
  {
    float distance = (opponentPositions[i] - ballPosition).norm();
    if(distance < closestOpponentDistance)
    {
      closestOpponentDistance = distance;
      closestOpponentIndex = static_cast<int>(i);
    }
  }
  
  // Detect contest situation
  bool contestExists = (closestTeammateDistance < contestDistance && 
                       closestOpponentDistance < contestDistance &&
                       std::abs(closestTeammateDistance - closestOpponentDistance) < contestDistance * 0.5f);
  
  if(contestExists)
  {
    if(state == noContest)
    {
      // New contest detected
      state = contestDetected;
      currentContest.ourPlayerNumber = closestTeammateIndex;
      currentContest.opponentPlayerNumber = closestOpponentIndex;
      currentContest.contestPosition = ballPosition;
      currentContest.contestStartTime = currentTime;
      currentContest.contestIntensity = 1.0f - std::abs(closestTeammateDistance - closestOpponentDistance) / contestDistance;
    }
    else
    {
      // Update existing contest
      currentContest.contestIntensity = 1.0f - std::abs(closestTeammateDistance - closestOpponentDistance) / contestDistance;
      
      // Check if support is needed
      if(currentTime - currentContest.contestStartTime > contestDuration && state == contestDetected)
      {
        defensiveRisk = evaluateDefensiveRisk(teammatePositions);
        if(defensiveRisk < maxDefensiveRisk)
        {
          state = supportNeeded;
          currentContest.needsSupport = true;
        }
      }
    }
  }
  else
  {
    // No contest or contest ended
    if(state != noContest)
    {
      state = noContest;
      currentContest = ContestInfo();
      supportPlayerNumber = -1;
      defensiveRisk = 0.f;
    }
  }
}

bool BallContestStatus::shouldSendSupport() const
{
  return state == supportNeeded && currentContest.needsSupport;
}

Vector2f BallContestStatus::getSupportPosition() const
{
  if(state == noContest)
    return Vector2f::Zero();
    
  // Calculate optimal support position
  // Position should be behind the contest, ready to receive pass or provide backup
  Vector2f contestToGoal = Vector2f(4500.f, 0.f) - currentContest.contestPosition; // Assuming opponent goal at (4500, 0)
  Vector2f supportDirection = contestToGoal.normalized();
  
  // Position support player 1 meter behind the contest
  return currentContest.contestPosition - supportDirection * 1000.f;
}

float BallContestStatus::evaluateDefensiveRisk(const std::vector<Vector2f>& teammatePositions) const
{
  // Simple risk evaluation based on defensive coverage
  // Higher risk if fewer players are in defensive positions
  
  const float ownGoalX = -4500.f; // Assuming own goal at (-4500, 0)
  const float defensiveZone = 2000.f; // Area around own goal to consider defensive
  
  int defendersCount = 0;
  for(const Vector2f& pos : teammatePositions)
  {
    if(pos.x() < ownGoalX + defensiveZone)
      defendersCount++;
  }
  
  // Risk increases as number of defenders decreases
  float maxDefenders = static_cast<float>(teammatePositions.size()) * 0.6f; // 60% should be defensive
  return std::max(0.f, (maxDefenders - defendersCount) / maxDefenders);
}