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
    // 4 rings × 24 positions = 96 bits
    // Position 0 of each ring is always "1" (sync marker for rotation detection)
    let code = '';
    for (let ring = 0; ring < 4; ring++) {
        code += '1'; // sync bit
        // Fill remaining 23 positions from hash
        const byteOffset = ring * 3;
        for (let i = 0; i < 3; i++) {
            const byte = hash[byteOffset + i].toString(2).padStart(8, '0');
            code += i === 2 ? byte.slice(0, 7) : byte; // 8+8+7 = 23 bits
        }
    }
    return code;
}

module.exports = { generateRingCode };
