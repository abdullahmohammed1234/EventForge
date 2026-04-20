const express = require('express');
const asyncWrapper = require('../utils/asyncWrapper');
const contentSecurity = require('../services/contentSecurityService');

const router = express.Router();

router.get(
  '/security',
  asyncWrapper(async (req, res, next) => {
    const thresholds = contentSecurity.getSecurityThresholds();
    res.json({
      success: true,
      data: thresholds,
    });
  })
);

router.put(
  '/security',
  asyncWrapper(async (req, res, next) => {
    const {
      minScore,
      maxScore,
      defaultThreshold,
      ageRestrictedThreshold,
      offensiveThreshold,
      sensitiveThreshold,
      discriminatoryThreshold,
    } = req.body;

    const newThresholds = {};
    if (minScore !== undefined) newThresholds.minScore = minScore;
    if (maxScore !== undefined) newThresholds.maxScore = maxScore;
    if (defaultThreshold !== undefined) newThresholds.defaultThreshold = defaultThreshold;
    if (ageRestrictedThreshold !== undefined) newThresholds.ageRestrictedThreshold = ageRestrictedThreshold;
    if (offensiveThreshold !== undefined) newThresholds.offensiveThreshold = offensiveThreshold;
    if (sensitiveThreshold !== undefined) newThresholds.sensitiveThreshold = sensitiveThreshold;
    if (discriminatoryThreshold !== undefined) newThresholds.discriminatoryThreshold = discriminatoryThreshold;

    const updated = contentSecurity.updateSecurityThresholds(newThresholds);
    res.json({
      success: true,
      message: 'Security thresholds updated',
      data: updated,
    });
  })
);

module.exports = router;