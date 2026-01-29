/**
 * @file BallContestProvider.cpp
 *
 * This file implements the BallContestProvider module.
 *
 * @author Generated for ball contest support strategy
 */

#include "BallContestProvider.h"
#include "Math/Eigen.h"

MAKE_MODULE(BallContestProvider);

BallContestProvider::BallContestProvider()
{
}

void BallContestProvider::update(BallContestStatus& ballContestStatus)
{
  // Check if ball contest support is enabled
  if(!enableBallContestSupport)
  {
    // If disabled, always set to no contest
    ballContestStatus.state = BallContestStatus::noContest;
    ballContestStatus.supportPlayerNumber = -1;
    ballContestStatus.defensiveRisk = 0.f;
    return;
  }

  // Get current positions
  std::vector<Vector2f> teammatePositions = getTeammatePositions();
  std::vector<Vector2f> opponentPositions = getOpponentPositions();
  
  // Update contest status
  ballContestStatus.update(theTeamBallModel.position, teammatePositions, 
                          opponentPositions, theFrameInfo.time);
  
  // Detect current contest
  bool contestDetected = detectContest();
  
  if(contestDetected)
  {
    if(ballContestStatus.state == BallContestStatus::noContest)
    {
      ballContestStatus.state = BallContestStatus::contestDetected;
      lastContestTime = theFrameInfo.time;
    }
    else if(ballContestStatus.state == BallContestStatus::contestDetected)
    {
      // Check if contest has lasted long enough to trigger support
      if(theFrameInfo.time - lastContestTime > minContestDuration)
      {
        float defensiveRisk = evaluateDefensiveRisk();
        if(defensiveRisk < maxDefensiveRisk)
        {
          ballContestStatus.state = BallContestStatus::supportNeeded;
          assignSupportPlayer(ballContestStatus);
        }
      }
    }
  }
  else
  {
    // No contest detected, reset state
    if(ballContestStatus.state != BallContestStatus::noContest)
    {
      ballContestStatus.state = BallContestStatus::noContest;
      ballContestStatus.supportPlayerNumber = -1;
      lastSupportPlayer = -1;
    }
  }
  
  // Update defensive risk
  ballContestStatus.defensiveRisk = evaluateDefensiveRisk();
}

bool BallContestProvider::detectContest()
{
  Vector2f ballPosition = theTeamBallModel.position;
  
  // Find closest teammate to ball
  float closestTeammateDistance = std::numeric_limits<float>::max();
  for(const Agent& agent : theAgentStates.agents)
  {
    float distance = (agent.currentPosition - ballPosition).norm();
    if(distance < closestTeammateDistance)
    {
      closestTeammateDistance = distance;
    }
  }
  
  // Simple contest detection: if closest teammate is very close to ball
  // and ball hasn't moved much recently, assume contest
  bool teammateNearBall = closestTeammateDistance < contestDetectionRadius;
  bool ballStationary = theTeamBallModel.velocity.norm() < 100.f; // mm/s
  
  return teammateNearBall && ballStationary;
}

void BallContestProvider::assignSupportPlayer(BallContestStatus& ballContestStatus)
{
  Vector2f ballPosition = theTeamBallModel.position;
  
  // Find best support candidate
  int bestCandidate = -1;
  float bestScore = -1.f;
  
  for(const Agent& agent : theAgentStates.agents)
  {
    // Skip goalkeeper and player already in contest
    if(agent.isGoalkeeper) continue;
    
    float distanceToBall = (agent.currentPosition - ballPosition).norm();
    if(distanceToBall < contestDetectionRadius) continue; // Already in contest
    if(distanceToBall > maxSupportRange) continue; // Too far away
    
    // Calculate support score based on distance and position
    float distanceScore = 1.f - (distanceToBall / maxSupportRange);
    float positionScore = agent.currentPosition.x() > -1000.f ? 1.f : 0.5f; // Prefer forward players
    
    float totalScore = distanceScore * 0.7f + positionScore * 0.3f;
    
    if(totalScore > bestScore)
    {
      bestScore = totalScore;
      bestCandidate = agent.number;
    }
  }
  
  if(bestCandidate != -1)
  {
    ballContestStatus.supportPlayerNumber = bestCandidate;
    ballContestStatus.state = BallContestStatus::supportNeeded;
    lastSupportPlayer = bestCandidate;
    
    // Calculate support target position
    Vector2f contestPosition = ballPosition;
    Vector2f supportDirection = (Vector2f(4500.f, 0.f) - contestPosition).normalized(); // Toward opponent goal
    ballContestStatus.supportTarget = contestPosition - supportDirection * supportDistance;
  }
}

float BallContestProvider::evaluateDefensiveRisk()
{
  int defendersCount = 0;
  int totalPlayers = 0;
  
  for(const Agent& agent : theAgentStates.agents)
  {
    if(agent.isGoalkeeper) continue;
    
    totalPlayers++;
    // Count players in defensive half
    if(agent.currentPosition.x() < 0.f)
      defendersCount++;
  }
  
  // Risk increases as defender ratio decreases
  float targetDefenderRatio = 0.4f; // 40% should be in defensive positions
  float currentRatio = totalPlayers > 0 ? static_cast<float>(defendersCount) / totalPlayers : 0.f;
  
  return std::max(0.f, (targetDefenderRatio - currentRatio) / targetDefenderRatio);
}

std::vector<Vector2f> BallContestProvider::getTeammatePositions()
{
  std::vector<Vector2f> positions;
  for(const Agent& agent : theAgentStates.agents)
  {
    positions.push_back(agent.currentPosition);
  }
  return positions;
}

std::vector<Vector2f> BallContestProvider::getOpponentPositions()
{
  std::vector<Vector2f> positions;
  // In a real implementation, this would use opponent tracking
  // For now, return empty vector as opponent positions are not easily available
  return positions;
}