/** Temporary 9-unit roster: Lumina / Vectra / Ferrum */

export const FACTIONS = {
  LUMINA: {
    id: 'LUMINA',
    nameKey: 'faction_lumina',
    color: '#38bdf8',
  },
  VECTRA: {
    id: 'VECTRA',
    nameKey: 'faction_vectra',
    color: '#f97316',
  },
  FERRUM: {
    id: 'FERRUM',
    nameKey: 'faction_ferrum',
    color: '#94a3b8',
  },
};

/**
 * attackMode: 'single' | 'splash'
 * targetMode: 'nearest' | 'strongest'
 * splashRange: used when attackMode === 'splash'
 * homing: Vectra Seeker flag (visual / future tracking)
 */
export const UNIT_TYPES = {
  PRISM: {
    type: 'PRISM',
    faction: 'LUMINA',
    nameKey: 'unit_prism',
    icon: '◇',
    cost: 10,
    sight: 3,
    damage: 1.5,
    attackCooldown: 1.0,
    attackMode: 'splash',
    splashRange: 1.2,
    targetMode: 'nearest',
  },
  HALO: {
    type: 'HALO',
    faction: 'LUMINA',
    nameKey: 'unit_halo',
    icon: '◎',
    cost: 14,
    sight: 2.5,
    damage: 1.2,
    attackCooldown: 1.1,
    attackMode: 'splash',
    splashRange: 1.8,
    targetMode: 'nearest',
  },
  AURORA: {
    type: 'AURORA',
    faction: 'LUMINA',
    nameKey: 'unit_aurora',
    icon: '✧',
    cost: 18,
    sight: 4,
    damage: 1.0,
    attackCooldown: 1.3,
    attackMode: 'splash',
    splashRange: 1.5,
    targetMode: 'nearest',
  },

  DART: {
    type: 'DART',
    faction: 'VECTRA',
    nameKey: 'unit_dart',
    icon: '▸',
    cost: 12,
    sight: 2,
    damage: 3,
    attackCooldown: 1.0,
    attackMode: 'splash',
    splashRange: 1.0,
    targetMode: 'nearest',
  },
  SEEKER: {
    type: 'SEEKER',
    faction: 'VECTRA',
    nameKey: 'unit_seeker',
    icon: '◈',
    cost: 16,
    sight: 2.5,
    damage: 3.5,
    attackCooldown: 1.2,
    attackMode: 'splash',
    splashRange: 1.0,
    targetMode: 'nearest',
    homing: true,
  },
  BARRAGE: {
    type: 'BARRAGE',
    faction: 'VECTRA',
    nameKey: 'unit_barrage',
    icon: '⫷',
    cost: 20,
    sight: 2,
    damage: 2.5,
    attackCooldown: 1.4,
    attackMode: 'splash',
    splashRange: 1.6,
    targetMode: 'nearest',
  },

  SPIKE: {
    type: 'SPIKE',
    faction: 'FERRUM',
    nameKey: 'unit_spike',
    icon: '▲',
    cost: 12,
    sight: 2.5,
    damage: 8,
    attackCooldown: 1.0,
    attackMode: 'single',
    targetMode: 'nearest',
  },
  APEX: {
    type: 'APEX',
    faction: 'FERRUM',
    nameKey: 'unit_apex',
    icon: '⬢',
    cost: 18,
    sight: 3,
    damage: 14,
    attackCooldown: 1.8,
    attackMode: 'single',
    targetMode: 'strongest',
  },
  RAIL: {
    type: 'RAIL',
    faction: 'FERRUM',
    nameKey: 'unit_rail',
    icon: '━',
    cost: 22,
    sight: 4,
    damage: 18,
    attackCooldown: 2.5,
    attackMode: 'single',
    targetMode: 'strongest',
  },
};

export const UNIT_KEYS_BY_FACTION = {
  LUMINA: ['PRISM', 'HALO', 'AURORA'],
  VECTRA: ['DART', 'SEEKER', 'BARRAGE'],
  FERRUM: ['SPIKE', 'APEX', 'RAIL'],
};

export function getUnitDef(typeKey) {
  return UNIT_TYPES[typeKey] ?? null;
}
