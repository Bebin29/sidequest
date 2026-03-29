/**
 * Generates a RoundCode-compatible message from a UUID.
 * Returns the first 27 characters of the UUID (uppercase hex, no dashes).
 * This fits within RoundCode's uuidConfiguration limit of 27 characters.
 * 27 hex chars = 108 bits of entropy — collision probability is negligible.
 */
function generateRingCode(uuid) {
    return uuid.replace(/-/g, '').toUpperCase().slice(0, 27);
}

module.exports = { generateRingCode };
