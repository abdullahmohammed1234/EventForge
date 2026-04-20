const { APIError } = require('../middleware/errorHandler');

const SECURITY_THRESHOLDS = {
  minScore: 0,
  maxScore: 100,
  defaultThreshold: 75,
  ageRestrictedThreshold: 60,
  offensiveThreshold: 70,
  sensitiveThreshold: 65,
  discriminatoryThreshold: 80,
};

const OFFENSIVE_PATTERNS = [
  /\b(hate|nazi|naziism|white power|supremac)\w*\b/i,
  /\b(kill|bomb|attack|terror)\s*(you|them|us|people|everyone|all)\b/i,
  /\b(rape|sexually\s*assault|non-consent)\b/i,
  /\b(pedophil|pedo|child\s*abus)\w*\b/i,
  /\b(weapon|gun|knife)\s*(bring|bring|car|hidden|conceal)\w*\b/i,
  /\b(drugs|heroin|cocaine|meth|ecstasy)\b/i,
  /\b(illegal\s*activit|criminal|felony)\b/i,
];

const DISCRIMINATORY_PATTERNS = [
  /\b(racial|racism|racist)\w*\b/i,
  /\b(sexist|sexism)\w*\b/i,
  /\b(homophob|transphob)\w*\b/i,
  /\b(antisemit|anti-sem)\w*\b/i,
  /\b(islaphob|anti-muslim)\w*\b/i,
  /\b(xenophob|xenophob)\w*\b/i,
  /\b(ableis|m\s*disab)\w*\b/i,
  /\b(end\s*the\s*white\s*race|white\s*genocide)\b/i,
  /\b(anti-.*(woman|black|asian|hispanic|indian|jew|gay|trans))\b/i,
];

const SENSITIVE_PATTERNS = [
  /\b(weapon|gun|firearm|ammo)\b/i,
  /\b(illegal\s*weapon|illegal\s*firearm)\b/i,
  /\b(prescription\s*drug|medication\s*abus)\b/i,
  /\b(self\s*harm|suicidcut)\w*\b/i,
  /\b(exploit|trafficking|slave)\w*\b/i,
  /\b(extremist|extremism)\b/i,
  /\b(incit|incitement)\b/i,
];

const AGE_INAPPROPRIATE_PATTERNS = [
  /\b(naked|nude|explicit\s*sexual|nsfw)\b/i,
  /\b(porn|xxx|adult\s*content)\b/i,
  /\b(sex\s*work|escort)\b/i,
  /\b(gambling|csino|poker)\b/i,
  /\b(alcohol|blood|violence|gore)\b/i,
];

const WARNING_PATTERNS = [
  /\b(Trigger\s*warning|sensitive\s*topic)\b/i,
  /\b(may\s*offend|may\s*disturb)\b/i,
  /\b(age\s*restrict|18\+|21\+)\b/i,
];

function calculateContentScore(text) {
  if (!text || typeof text !== 'string') {
    return { score: 0, flags: [] };
  }

  const flags = [];
  let totalWeight = 0;

  for (const pattern of OFFENSIVE_PATTERNS) {
    if (pattern.test(text)) {
      flags.push('offensive');
      totalWeight += 15;
      break;
    }
  }

  for (const pattern of DISCRIMINATORY_PATTERNS) {
    if (pattern.test(text)) {
      flags.push('discriminatory');
      totalWeight += 20;
      break;
    }
  }

  for (const pattern of SENSITIVE_PATTERNS) {
    if (pattern.test(text)) {
      flags.push('sensitive');
      totalWeight += 12;
      break;
    }
  }

  for (const pattern of AGE_INAPPROPRIATE_PATTERNS) {
    if (pattern.test(text)) {
      flags.push('age_inappropriate');
      totalWeight += 10;
      break;
    }
  }

  for (const pattern of WARNING_PATTERNS) {
    if (pattern.test(text)) {
      flags.push('warning_present');
      totalWeight += 5;
      break;
    }
  }

  const score = Math.min(totalWeight, SECURITY_THRESHOLDS.maxScore);

  return { score, flags: [...new Set(flags)] };
}

function analyzeContent(text) {
  const { score, flags } = calculateContentScore(text);

  return {
    score,
    flags,
    isSafe: score < SECURITY_THRESHOLDS.defaultThreshold,
    isAgeRestricted: score >= SECURITY_THRESHOLDS.ageRestrictedThreshold,
    isOffensive: flags.includes('offensive'),
    isDiscriminatory: flags.includes('discriminatory'),
    isSensitive: flags.includes('sensitive'),
    thresholds: {
      default: SECURITY_THRESHOLDS.defaultThreshold,
      ageRestricted: SECURITY_THRESHOLDS.ageRestrictedThreshold,
      offensive: SECURITY_THRESHOLDS.offensiveThreshold,
      sensitive: SECURITY_THRESHOLDS.sensitiveThreshold,
      discriminatory: SECURITY_THRESHOLDS.discriminatoryThreshold,
    },
  };
}

function checkEventSecurity(eventData) {
  const titleAnalysis = analyzeContent(eventData.title || '');
  const descriptionAnalysis = analyzeContent(eventData.description || '');
  const tagsAnalysis = analyzeContent((eventData.tags || []).join(' '));

  const combinedScore = Math.max(
    titleAnalysis.score,
    descriptionAnalysis.score,
    tagsAnalysis.score
  );

  const allFlags = [
    ...titleAnalysis.flags,
    ...descriptionAnalysis.flags,
    ...tagsAnalysis.flags,
  ];

  const uniqueFlags = [...new Set(allFlags)];

  const hasHighRiskContent = titleAnalysis.isOffensive ||
    titleAnalysis.isDiscriminatory ||
    descriptionAnalysis.isOffensive ||
    descriptionAnalysis.isDiscriminatory;

  const needsAutoMinAge = uniqueFlags.includes('age_inappropriate') ||
    uniqueFlags.includes('offensive');

  return {
    score: combinedScore,
    flags: uniqueFlags,
    isSafe: combinedScore < SECURITY_THRESHOLDS.defaultThreshold,
    needsReview: combinedScore >= SECURITY_THRESHOLDS.defaultThreshold && combinedScore < SECURITY_THRESHOLDS.offensiveThreshold,
    shouldBlock: hasHighRiskContent || combinedScore >= SECURITY_THRESHOLDS.offensiveThreshold,
    requiresMinAge: needsAutoMinAge,
    recommendedMinAge: needsAutoMinAge ? 18 : null,
    analysis: {
      title: titleAnalysis,
      description: descriptionAnalysis,
      tags: tagsAnalysis,
    },
  };
}

function checkCommentSecurity(content) {
  const analysis = analyzeContent(content);

  return {
    isSafe: analysis.isSafe,
    shouldBlock: analysis.isOffensive || analysis.isDiscriminatory || analysis.score >= SECURITY_THRESHOLDS.offensiveThreshold,
    flags: analysis.flags,
    score: analysis.score,
  };
}

function validateEventCreation(eventData) {
  const securityCheck = checkEventSecurity(eventData);

  if (securityCheck.shouldBlock) {
    return {
      valid: false,
      reason: 'Content violates security guidelines',
      flags: securityCheck.flags,
      score: securityCheck.score,
    };
  }

  if (securityCheck.needsReview) {
    return {
      valid: true,
      flagged: true,
      reason: 'Content flagged for review',
      flags: securityCheck.flags,
      score: securityCheck.score,
    };
  }

  return {
    valid: true,
    flagged: false,
    recommendedMinAge: securityCheck.recommendedMinAge,
  };
}

function getSecurityThresholds() {
  return { ...SECURITY_THRESHOLDS };
}

function updateSecurityThresholds(newThresholds) {
  Object.assign(SECURITY_THRESHOLDS, newThresholds);
  return { ...SECURITY_THRESHOLDS };
}

module.exports = {
  analyzeContent,
  checkEventSecurity,
  checkCommentSecurity,
  validateEventCreation,
  getSecurityThresholds,
  calculateContentScore,
  updateSecurityThresholds,
};