/**
 * OpenRouteService Configuration
 * API Documentation: https://openrouteservice.org/dev/#/api-docs
 */

const ORS_API_KEY = process.env.ORS_API_KEY;

const ORS_BASE_URL = 'https://api.openrouteservice.org';

module.exports = {
  ORS_API_KEY,
  ORS_BASE_URL,
  
  // Default profile for directions (driving-car, cycling-regular, foot-walking)
  DEFAULT_PROFILE: 'driving-car',
  
  // Available profiles
  PROFILES: {
    driving_car: 'driving-car',
    driving_hgv: 'driving-hgv',
    cycling_regular: 'cycling-regular',
    cycling_road: 'cycling-road',
    cycling_mountain: 'cycling-mountain',
    cycling_electric: 'cycling-electric',
    foot_walking: 'foot-walking',
    foot_hiking: 'foot-hiking',
  },
  
  // Geocoding base URL (for address search)
  GEOCODING_BASE_URL: 'https://api.openrouteservice.org/geocode/search',
  
  // Geocoding reverse URL (for coordinates to address)
  GEOCODING_REVERSE_URL: 'https://api.openrouteservice.org/geocode/reverse',
};