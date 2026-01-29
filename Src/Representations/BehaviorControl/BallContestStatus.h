/**
 * @file BallContestStatus.h
 *
 * This file declares a representation that tracks ball contest situations
 * and determines when support is needed.
 *
 * @author Generated for ball contest support strategy
 */

#pragma once

#include "Math/Eigen.h"
#include "Streaming/AutoStreamable.h"

STREAMABLE(BallContestStatus,
{
  ENUM(ContestState,
  {,
    noContest,        /**< No ball contest is happening */
    contestDetected,  /**< Ball contest detected between two players */
    supportNeeded,    /**< Support is needed for the contest */
    supportDispatched /**< Support has been dispatched */
  });

  STREAMABLE(ContestInfo,
  {,
    (int)(-1) ourPlayerNumber,      /**< Number of our player involved in contest */
    (int)(-1) opponentPlayerNumber, /**< Number of opponent player (if known) */
    (Vector2f)(Vector2f::Zero()) contestPosition, /**< Position where contest is happening */
    (unsigned)(0) contestStartTime, /**< When the contest started */
    (float)(0.f) contestIntensity,  /**< How intense the contest is (0-1) */
    (bool)(false) needsSupport,     /**< Whether this contest needs support */
  });

  /** Updates the contest status based on current game state */
  void update(const Vector2f& ballPosition, 
              const std::vector<Vector2f>& teammatePositions,
              const std::vector<Vector2f>& opponentPositions,
              unsigned currentTime);

  /** Determines if support should be sent */
  bool shouldSendSupport() const;

  /** Gets the best support position */
  Vector2f getSupportPosition() const;

  /** Evaluates defensive risk of sending support */
  float evaluateDefensiveRisk(const std::vector<Vector2f>& teammatePositions) const;

,
  (ContestState)(noContest) state,           /**< Current contest state */
  (ContestInfo) currentContest,              /**< Information about current contest */
  (int)(-1) supportPlayerNumber,             /**< Player number assigned to provide support */
  (Vector2f)(Vector2f::Zero()) supportTarget, /**< Target position for support player */
  (float)(0.f) defensiveRisk,                /**< Risk level of current defensive setup (0-1) */
  (unsigned)(0) lastUpdateTime,              /**< Last time this was updated */
});