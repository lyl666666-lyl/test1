/**
 * @file BallContestSupport.h
 *
 * This file declares a role for providing support during ball contests.
 * When two players are contesting for the ball, this role ensures that
 * at least one additional player provides support while maintaining
 * defensive stability.
 *
 * @author Generated for ball contest support strategy
 */

#pragma once

#include "Modules/BehaviorControl/StrategyBehaviorControl/Behavior.h"
#include "Tools/BehaviorControl/Strategy/ActiveRole.h"
#include "Tools/BehaviorControl/Strategy/Agent.h"

class BallContestSupport : public ActiveRole
{
  STREAMABLE(Parameters,
  {,
    (float)(800.f) supportDistance,        /**< Distance to maintain from contest position */
    (float)(1500.f) maxSupportDistance,    /**< Maximum distance to provide support from */
    (float)(0.6f) maxDefensiveRisk,        /**< Maximum acceptable defensive risk (0-1) */
    (float)(500.f) contestDetectionRadius, /**< Radius to detect ball contests */
    (unsigned)(2000) minContestDuration,   /**< Minimum contest duration before support (ms) */
    (float)(0.8f) supportPositionWeight,   /**< Weight for optimal support positioning */
    (float)(0.2f) defensivePositionWeight, /**< Weight for maintaining defensive position */
  });

  /**
   * Executes the ball contest support role.
   * @param self The agent executing this role.
   * @param teammates The other agents in the team.
   * @return The skill request for supporting the ball contest.
   */
  SkillRequest execute(const Agent& self, const Agents& teammates) override;

  /**
   * Determines if this agent should provide contest support.
   * @param self The agent to evaluate.
   * @param teammates All team agents.
   * @return True if this agent should provide support.
   */
  bool shouldProvideSupport(const Agent& self, const Agents& teammates);

  /**
   * Calculates the optimal support position.
   * @param contestPosition Position where the contest is happening.
   * @param contestantPosition Position of our player in contest (unused).
   * @return Optimal position for providing support.
   */
  Vector2f calculateSupportPosition(const Vector2f& contestPosition, 
                                   const Vector2f& contestantPosition);

  /**
   * Evaluates if sending support would compromise defense.
   * @param self The agent considering providing support.
   * @param teammates All team agents.
   * @return Risk level (0-1, where 1 is maximum risk).
   */
  float evaluateDefensiveRisk(const Agent& self, const Agents& teammates);

  /**
   * Detects if a ball contest is currently happening.
   * @param teammates All team agents.
   * @return True if a contest requiring support is detected.
   */
  bool detectBallContest(const Agents& teammates);

  void reset() override;
  void preProcess() override;

private:
  Parameters p;
  Vector2f lastSupportPosition = Vector2f::Zero();
  unsigned contestStartTime = 0;
  bool wasInContest = false;
  int supportingPlayer = -1; /**< Player number currently providing support */
};