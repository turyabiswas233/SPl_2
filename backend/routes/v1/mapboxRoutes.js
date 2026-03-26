const express = require("express");
const { getLocationsBySearch } = require("../../controllers/mapboxController");
const router = express.Router();

router.get("/search-location", getLocationsBySearch);

module.exports = router;
