/**
 * @file BallContestProvider.h
 *
 * This file declares a module that detects ball contest situations
 * and determines when support should be provided.
 *
 * @author Generated for ball contest support strategy
 */

#pragma once

#include "Framework/Module.h"
#include "Representations/BehaviorControl/BallContestStatus.h"
#include "Representations/BehaviorControl/AgentStates.h"
#include "Representations/Communication/ReceivedTeamMessages.h"
#include "Representations/Infrastructure/FrameInfo.h"
#include "Representations/Modeling/BallModel.h"
#include "Representations/Modeling/RobotPose.h"
#include "Representations/Modeling/TeamBallModel.h"

MODULE(BallContestProvider,
{,
  REQUIRES(AgentStates),
  REQUIRES(BallModel),
  REQUIRES(FrameInfo),
  REQUIRES(ReceivedTeamMessages),
  REQUIRES(RobotPose),
  REQUIRES(TeamBallModel),
  PROVIDES(BallContestStatus),
  LOADS_PARAMETERS(
  {,
    (bool)(true) enableBallContestSupport,    /**< Enable/disable ball contest support functionality */
    (float)(500.f) contestDetectionRadius,    /**< Distance to consider players in contest */
    (unsigned)(1500) minContestDuration,      /**< Minimum duration before triggering support */
    (float)(0.7f) maxDefensiveRisk,          /**< Maximum acceptable defensive risk */
    (float)(1000.f) supportDistance,         /**< Preferred distance for support positioning */
    (float)(2000.f) maxSupportRange,         /**< Maximum range to provide support */
    (int)(2) minDefenders,                   /**< Minimum number of defenders to maintain */
  }),
});

class BallContestProvider : public BallContestProviderBase
{
public:
  /** Constructor. */
  BallContestProvider();

private:
  /**
   * Updates the ball contest status.
   * @param ballContestStatus The provided ball contest status.
   */
  void update(BallContestStatus& ballContestStatus) override;

  /**
   * Detects if a ball contest is currently happening.
   * @return True if a contest is detected.
   */
  bool detectContest();

  /**
   * Determines which player should provide support.
   * @param ballContestStatus The contest status to update.
   */
  void assignSupportPlayer(BallContestStatus& ballContestStatus);

  /**
   * Evaluates the defensive risk of sending support.
   * @return Risk level (0-1).
   */
  float evaluateDefensiveRisk();

  /**
   * Gets positions of all teammates.
   * @return Vector of teammate positions.
   */
  std::vector<Vector2f> getTeammatePositions();

  /**
   * Gets estimated positions of opponents.
   * @return Vector of opponent positions.
   */
  std::vector<Vector2f> getOpponentPositions();

  unsigned lastContestTime = 0;  /**< Last time a contest was detected */
  int lastSupportPlayer = -1;    /**< Last player assigned to provide support */
};