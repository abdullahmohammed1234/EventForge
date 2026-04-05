/**
 * OpenRouteService Controller
 * Provides directions, distance calculations, and geocoding via OpenRouteService API
 */

const axios = require('axios');
const { 
  ORS_API_KEY, 
  ORS_BASE_URL, 
  DEFAULT_PROFILE,
  PROFILES,
  GEOCODING_BASE_URL,
  GEOCODING_REVERSE_URL 
} = require('../config/openrouteservice');
const asyncWrapper = require('../utils/asyncWrapper');

/**
 * Get directions between two points
 * GET /api/maps/directions?from_lng=&from_lat=&to_lng=&to_lat=&profile=driving-car
 */
exports.getDirections = asyncWrapper(async (req, res) => {
  const { from_lng, from_lat, to_lng, to_lat, profile = DEFAULT_PROFILE } = req.query;

  // Validate required parameters
  if (!from_lng || !from_lat || !to_lng || !to_lat) {
    return res.status(400).json({
      success: false,
      error: 'Missing required parameters: from_lng, from_lat, to_lng, to_lat',
    });
  }

  // Validate coordinates are valid numbers
  const fromLng = parseFloat(from_lng);
  const fromLat = parseFloat(from_lat);
  const toLng = parseFloat(to_lng);
  const toLat = parseFloat(to_lat);

  if (isNaN(fromLng) || isNaN(fromLat) || isNaN(toLng) || isNaN(toLat)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid coordinates. All coordinates must be valid numbers.',
    });
  }

  // Validate profile
  const validProfile = PROFILES[profile] || DEFAULT_PROFILE;

  try {
    const response = await axios.get(`${ORS_BASE_URL}/v2/directions/${validProfile}`, {
      params: {
        api_key: ORS_API_KEY,
        start: `${fromLng},${fromLat}`,
        end: `${toLng},${toLat}`,
      },
    });

    res.json({
      success: true,
      data: response.data,
    });
  } catch (error) {
    console.error('OpenRouteService Directions Error:', error.response?.data || error.message);
    res.status(502).json({
      success: false,
      error: 'Failed to get directions from OpenRouteService',
      details: error.response?.data?.error || error.message,
    });
  }
});

/**
 * Get distance between two points
 * GET /api/maps/distance?from_lng=&from_lat=&to_lng=&to_lat=&profile=driving-car
 */
exports.getDistance = asyncWrapper(async (req, res) => {
  const { from_lng, from_lat, to_lng, to_lat, profile = DEFAULT_PROFILE } = req.query;

  // Validate required parameters
  if (!from_lng || !from_lat || !to_lng || !to_lat) {
    return res.status(400).json({
      success: false,
      error: 'Missing required parameters: from_lng, from_lat, to_lng, to_lat',
    });
  }

  const fromLng = parseFloat(from_lng);
  const fromLat = parseFloat(from_lat);
  const toLng = parseFloat(to_lng);
  const toLat = parseFloat(to_lat);

  if (isNaN(fromLng) || isNaN(fromLat) || isNaN(toLng) || isNaN(toLat)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid coordinates. All coordinates must be valid numbers.',
    });
  }

  const validProfile = PROFILES[profile] || DEFAULT_PROFILE;

  try {
    const response = await axios.get(`${ORS_BASE_URL}/v2/directions/${validProfile}`, {
      params: {
        api_key: ORS_API_KEY,
        start: `${fromLng},${fromLat}`,
        end: `${toLng},${toLat}`,
      },
    });

    const route = response.data.features?.[0];
    if (!route) {
      return res.status(404).json({
        success: false,
        error: 'No route found between the specified points',
      });
    }

    // Extract distance (in meters) and duration (in seconds)
    const distanceMeters = route.properties?.segments?.[0]?.distance || 0;
    const durationSeconds = route.properties?.segments?.[0]?.duration || 0;

    res.json({
      success: true,
      data: {
        distance_meters: distanceMeters,
        distance_km: Math.round(distanceMeters / 1000 * 10) / 10, // Round to 1 decimal
        duration_seconds: durationSeconds,
        duration_minutes: Math.round(durationSeconds / 60),
        duration_formatted: _formatDuration(durationSeconds),
      },
    });
  } catch (error) {
    console.error('OpenRouteService Distance Error:', error.response?.data || error.message);
    res.status(502).json({
      success: false,
      error: 'Failed to calculate distance from OpenRouteService',
      details: error.response?.data?.error || error.message,
    });
  }
});

/**
 * Geocode an address to coordinates
 * GET /api/maps/geocode?address=Vancouver,BC
 */
exports.geocode = asyncWrapper(async (req, res) => {
  const { address } = req.query;

  if (!address) {
    return res.status(400).json({
      success: false,
      error: 'Missing required parameter: address',
    });
  }

  try {
    const response = await axios.get(GEOCODING_BASE_URL, {
      params: {
        api_key: ORS_API_KEY,
        text: address,
        size: 1, // Get only the best match
      },
    });

    const features = response.data.features;
    if (!features || features.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'No results found for the given address',
      });
    }

    const bestMatch = features[0];
    const [lng, lat] = bestMatch.geometry.coordinates;

    res.json({
      success: true,
      data: {
        lat,
        lng,
        label: bestMatch.properties.label,
        confidence: bestMatch.properties.confidence,
      },
    });
  } catch (error) {
    console.error('OpenRouteService Geocode Error:', error.response?.data || error.message);
    res.status(502).json({
      success: false,
      error: 'Failed to geocode address from OpenRouteService',
      details: error.response?.data?.error || error.message,
    });
  }
});

/**
 * Reverse geocode coordinates to address
 * GET /api/maps/reverse-geocode?lat=&lng=
 */
exports.reverseGeocode = asyncWrapper(async (req, res) => {
  const { lat, lng } = req.query;

  if (!lat || !lng) {
    return res.status(400).json({
      success: false,
      error: 'Missing required parameters: lat, lng',
    });
  }

  const latNum = parseFloat(lat);
  const lngNum = parseFloat(lng);

  if (isNaN(latNum) || isNaN(lngNum)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid coordinates. Lat and lng must be valid numbers.',
    });
  }

  try {
    const response = await axios.get(GEOCODING_REVERSE_URL, {
      params: {
        api_key: ORS_API_KEY,
        'point.lng': lngNum,
        'point.lat': latNum,
        size: 1,
      },
    });

    const features = response.data.features;
    if (!features || features.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'No address found for the given coordinates',
      });
    }

    const bestMatch = features[0];

    res.json({
      success: true,
      data: {
        lat: latNum,
        lng: lngNum,
        label: bestMatch.properties.label,
        address: bestMatch.properties.name,
        city: bestMatch.properties.locality,
        country: bestMatch.properties.country,
      },
    });
  } catch (error) {
    console.error('OpenRouteService Reverse Geocode Error:', error.response?.data || error.message);
    res.status(502).json({
      success: false,
      error: 'Failed to reverse geocode from OpenRouteService',
      details: error.response?.data?.error || error.message,
    });
  }
});

/**
 * Search for locations by query
 * GET /api/maps/search?query=Vancouver
 */
exports.searchLocations = asyncWrapper(async (req, res) => {
  const { query } = req.query;

  if (!query) {
    return res.status(400).json({
      success: false,
      error: 'Missing required parameter: query',
    });
  }

  try {
    const response = await axios.get(GEOCODING_BASE_URL, {
      params: {
        api_key: ORS_API_KEY,
        text: query,
        size: 5, // Get up to 5 results
      },
    });

    const features = response.data.features;
    if (!features || features.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'No locations found for the given query',
      });
    }

    const results = features.map((feature) => {
      const [lng, lat] = feature.geometry.coordinates;
      return {
        lat,
        lng,
        label: feature.properties.label,
        name: feature.properties.name,
        city: feature.properties.locality,
        country: feature.properties.country,
        confidence: feature.properties.confidence,
      };
    });

    res.json({
      success: true,
      data: results,
    });
  } catch (error) {
    console.error('OpenRouteService Search Error:', error.response?.data || error.message);
    res.status(502).json({
      success: false,
      error: 'Failed to search locations from OpenRouteService',
      details: error.response?.data?.error || error.message,
    });
  }
});

/**
 * Get OpenStreetMap search URL for an address
 * GET /api/maps/osm-search?address=123+Main+St+City
 */
exports.getOsmSearchUrl = asyncWrapper(async (req, res) => {
  const { address } = req.query;

  if (!address) {
    return res.status(400).json({
      success: false,
      error: 'Missing required parameter: address',
    });
  }

  try {
    const response = await axios.get(GEOCODING_BASE_URL, {
      params: {
        api_key: ORS_API_KEY,
        text: address,
        size: 1,
      },
    });

    const features = response.data.features;
    if (!features || features.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'No results found for the given address',
      });
    }

    const bestMatch = features[0];
    const [lng, lat] = bestMatch.geometry.coordinates;
    const label = bestMatch.properties.label;

    const osmUrl = `https://www.openstreetmap.org/search?query=${encodeURIComponent(label)}`;

    res.json({
      success: true,
      data: {
        url: osmUrl,
        lat,
        lng,
        label,
      },
    });
  } catch (error) {
    console.error('OpenRouteService OSM Search Error:', error.response?.data || error.message);
    res.status(502).json({
      success: false,
      error: 'Failed to get OSM search URL',
      details: error.response?.data?.error || error.message,
    });
  }
});

/**
 * Helper function to format duration in a readable way
 * @param {number} seconds - Duration in seconds
 * @returns {string} Formatted duration string
 */
function _formatDuration(seconds) {
  if (seconds < 60) {
    return `${Math.round(seconds)} seconds`;
  }
  
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) {
    const remainingSeconds = seconds % 60;
    if (remainingSeconds > 0) {
      return `${minutes} min ${Math.round(remainingSeconds)} sec`;
    }
    return `${minutes} min`;
  }
  
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  if (remainingMinutes > 0) {
    return `${hours} hr ${remainingMinutes} min`;
  }
  return `${hours} hr`;
}