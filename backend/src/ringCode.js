const crypto = require('crypto');

/**
 * Generates a 96-character binary ring code from a UUID.
 * 4 rings × 24 positions = 96 bits.
 * Each bit determines segment boundaries:
 *   "1" = start new segment, "0" = continue previous segment.
 * Every ring is fully filled — only the segment lengths vary.
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
