const crypto = require('crypto');

/**
 * Generates a 72-character binary ring code from a UUID.
 * 3 rings × 24 positions = 72 bits.
 * Each bit determines segment boundaries:
 *   "1" = start new segment, "0" = continue previous segment.
 * Every ring is fully filled — only the segment lengths vary.
 */
function generateRingCode(uuid) {
    const hash = crypto.createHash('sha256').update(uuid).digest();
    // Take first 9 bytes = 72 bits
    let code = '';
    for (let i = 0; i < 9; i++) {
        code += hash[i].toString(2).padStart(8, '0');
    }
    return code;
}

module.exports = { generateRingCode };
