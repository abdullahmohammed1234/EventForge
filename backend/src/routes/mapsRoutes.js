/**
 * Maps API Routes
 * Endpoints for OpenRouteService directions, distance, and geocoding
 */

const express = require('express');
const router = express.Router();
const mapsController = require('../controllers/mapsController');

// GET /api/maps/directions - Get directions between two points
router.get('/directions', mapsController.getDirections);

// GET /api/maps/distance - Get distance between two points
router.get('/distance', mapsController.getDistance);

// GET /api/maps/geocode - Convert address to coordinates
router.get('/geocode', mapsController.geocode);

// GET /api/maps/reverse-geocode - Convert coordinates to address
router.get('/reverse-geocode', mapsController.reverseGeocode);

// GET /api/maps/search - Search for locations by query
router.get('/search', mapsController.searchLocations);

// GET /api/maps/osm-search - Get OpenStreetMap search URL for an address
router.get('/osm-search', mapsController.getOsmSearchUrl);

module.exports = router;