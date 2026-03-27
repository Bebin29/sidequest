const crypto = require('crypto');

/**
 * Generates a 96-character binary ring code from a UUID.
 * 4 rings × 24 positions = 96 bits, encoded as "0" and "1".
 * Each ring is a concentric circle around the profile image.
 */
function generateRingCode(uuid) {
    const hash = crypto.createHash('sha256').update(uuid).digest();
    // Take first 12 bytes = 96 bits
    let code = '';
    for (let i = 0; i < 12; i++) {
        code += hash[i].toString(2).padStart(8, '0');
    }
    return code;
}

module.exports = { generateRingCode };
