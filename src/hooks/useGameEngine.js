import { useState, useEffect, useRef, useCallback } from 'react';
import { UNIT_TYPES } from '../data/units';
import { NORMAL_MONSTERS } from '../data/monsters';
import { BOSS_MONSTERS } from '../data/bosses';

export const TRACK_PATH = [
  { x: 0, y: 0 }, { x: 1, y: 0 }, { x: 2, y: 0 }, { x: 3, y: 0 }, { x: 4, y: 0 },
  { x: 4, y: 1 }, { x: 4, y: 2 }, { x: 4, y: 3 }, { x: 4, y: 4 },
  { x: 3, y: 4 }, { x: 2, y: 4 }, { x: 1, y: 4 }, { x: 0, y: 4 },
  { x: 0, y: 3 }, { x: 0, y: 2 }, { x: 0, y: 1 },
];

export const TIMELINE = [
  { duration: 99, type: 'COMBAT', wave: 1 },
  { duration: 10, type: 'REST', wave: 1 },
  { duration: 99, type: 'COMBAT', wave: 2 },
  { duration: 10, type: 'REST', wave: 2 },
  { duration: 99, type: 'COMBAT', wave: 3 },
  { duration: 10, type: 'REST', wave: 3 },
  { duration: 99, type: 'COMBAT', wave: 4 },
  { duration: 15, type: 'REST', wave: 4 },
  { duration: 99, type: 'COMBAT', wave: 5 },
];

const TOTAL_DURATION = TIMELINE.reduce((sum, p) => sum + p.duration, 0);
const UI_INTERVAL_MS = 1000 / 20; // ~20fps React sync
export const MAX_MONSTERS = 99;

function getMonsterPosition(progress) {
  const clamped = Math.min(Math.max(progress, 0), 15.999);
  const index = Math.floor(clamped);
  const nextIndex = Math.min(index + 1, 15);
  const fraction = clamped - index;
  const p1 = TRACK_PATH[index];
  const p2 = TRACK_PATH[nextIndex];
  return {
    mx: p1.x + (p2.x - p1.x) * fraction,
    my: p1.y + (p2.y - p1.y) * fraction,
  };
}

function getDistance(ux, uy, mx, my) {
  return Math.hypot(ux - mx, uy - my);
}

function getCurrentPhase(timeRemaining) {
  let elapsed = TOTAL_DURATION - timeRemaining;
  for (const p of TIMELINE) {
    if (elapsed < p.duration) return { ...p, timeInPhase: elapsed };
    elapsed -= p.duration;
  }
  return { type: 'END', wave: 5, timeInPhase: 0, duration: 0 };
}

function createInitialSimState() {
  return {
    monsters: [],
    units: [],
    attacks: [],
    gold: 50,
    timeRemaining: TOTAL_DURATION,
    gameOver: null,
    lastSpawnTime: 0,
    spawnedInWave: 0,
    bossSpawnedForWave: false,
  };
}

export function useGameEngine({ enabled = false } = {}) {
  const [gold, setGold] = useState(50);
  const [monsters, setMonsters] = useState([]);
  const [units, setUnits] = useState([]);
  const [attacks, setAttacks] = useState([]);
  const [gameOver, setGameOver] = useState(null);
  const [timeRemaining, setTimeRemaining] = useState(TOTAL_DURATION);

  const stateRef = useRef(createInitialSimState());
  const nextIdRef = useRef(1);
  const lastUiPushRef = useRef(0);

  const allocId = () => nextIdRef.current++;

  const pushSnapshot = useCallback(() => {
    const s = stateRef.current;
    setMonsters(s.monsters.map((m) => ({ ...m })));
    setUnits(s.units.map((u) => ({ ...u })));
    setAttacks(s.attacks.map((a) => ({ ...a })));
    setGold(s.gold);
    setTimeRemaining(Math.ceil(s.timeRemaining));
    setGameOver(s.gameOver);
    lastUiPushRef.current = performance.now();
  }, []);

  const flushToReact = useCallback((force = false) => {
    if (!force && performance.now() - lastUiPushRef.current < UI_INTERVAL_MS) {
      return;
    }
    pushSnapshot();
  }, [pushSnapshot]);

  const flushNow = useCallback(() => {
    pushSnapshot();
  }, [pushSnapshot]);

  const spawnMonsterInto = useCallback((sim, wave, options = {}) => {
    const { isBoss = false, bossIndex, isFinalBoss = false } = options;
    let template;
    if (isBoss) {
      const index =
        bossIndex !== undefined
          ? Math.min(bossIndex, BOSS_MONSTERS.length - 1)
          : Math.min(wave - 1, BOSS_MONSTERS.length - 1);
      template = BOSS_MONSTERS[index];
    } else {
      const maxNormalIndex = Math.min(wave, NORMAL_MONSTERS.length);
      const normalIndex = Math.floor(Math.random() * maxNormalIndex);
      template = NORMAL_MONSTERS[normalIndex];
    }

    const hp = template.hpBase + template.hpScale * (wave - 1);
    sim.monsters.push({
      id: allocId(),
      progress: 0,
      hp,
      maxHp: hp,
      speed: template.speed,
      reward: template.reward,
      color: template.color,
      isBoss,
      isFinalBoss,
      type: template.type,
    });
  }, []);

  const buildUnit = useCallback((x, y, typeKey) => {
    const sim = stateRef.current;
    if (sim.gameOver) return;
    const typeDef = UNIT_TYPES[typeKey];
    if (!typeDef || sim.gold < typeDef.cost) return;
    if (sim.units.some((u) => u.x === x && u.y === y)) return;

    sim.gold -= typeDef.cost;
    sim.units = [
      ...sim.units,
      {
        id: allocId(),
        x,
        y,
        type: typeDef.type,
        faction: typeDef.faction,
        lastAttackTime: 0,
        level: 1,
        totalSpent: typeDef.cost,
      },
    ];
    flushNow();
  }, [flushNow]);

  const upgradeUnit = useCallback((x, y) => {
    const sim = stateRef.current;
    if (sim.gameOver) return;
    const unit = sim.units.find((u) => u.x === x && u.y === y);
    if (!unit) return;
    const typeDef = UNIT_TYPES[unit.type];
    const cost = typeDef.cost * unit.level;
    if (sim.gold < cost) return;

    sim.gold -= cost;
    sim.units = sim.units.map((u) =>
      u.x === x && u.y === y
        ? { ...u, level: u.level + 1, totalSpent: u.totalSpent + cost }
        : u
    );
    flushNow();
  }, [flushNow]);

  const sellUnit = useCallback((x, y) => {
    const sim = stateRef.current;
    if (sim.gameOver) return;
    const unitToSell = sim.units.find((u) => u.x === x && u.y === y);
    if (!unitToSell) return;

    sim.gold += Math.floor(unitToSell.totalSpent / 2);
    sim.units = sim.units.filter((u) => u !== unitToSell);
    flushNow();
  }, [flushNow]);

  const restartGame = useCallback(() => {
    stateRef.current = createInitialSimState();
    nextIdRef.current = 1;
    lastUiPushRef.current = 0;
    flushNow();
  }, [flushNow]);

  // Main game loop — only while enabled
  useEffect(() => {
    if (!enabled) return;

    let animationFrameId;
    let lastTime = performance.now();
    lastUiPushRef.current = 0;

    // Fresh start when enabling from title screen with leftover state
    if (!stateRef.current.gameOver && stateRef.current.timeRemaining === TOTAL_DURATION) {
      stateRef.current.lastSpawnTime = performance.now();
    }

    const loop = (currentTime) => {
      const sim = stateRef.current;

      if (sim.gameOver) {
        animationFrameId = requestAnimationFrame(loop);
        return;
      }

      const dt = Math.min((currentTime - lastTime) / 1000, 0.05);
      lastTime = currentTime;

      // Timer (integrated)
      sim.timeRemaining -= dt;
      if (sim.timeRemaining <= 0) {
        sim.timeRemaining = 0;
        sim.gameOver = 'win';
        flushNow();
        animationFrameId = requestAnimationFrame(loop);
        return;
      }

      // 1. Move monsters
      let nextMonsters = sim.monsters.map((m) => ({
        ...m,
        progress: m.progress + m.speed * dt,
      }));

      if (nextMonsters.some((m) => m.progress >= 16) || nextMonsters.length > MAX_MONSTERS) {
        sim.monsters = nextMonsters;
        sim.gameOver = 'lose';
        flushNow();
        animationFrameId = requestAnimationFrame(loop);
        return;
      }

      // Cache positions once per frame
      const monstersWithPos = nextMonsters.map((m) => ({
        ...m,
        ...getMonsterPosition(m.progress),
      }));

      // 2. Unit attacks
      const nowTime = currentTime / 1000;
      const newAttacks = [];
      let nextAttacks = sim.attacks.filter((a) => nowTime - a.time < 0.2);

      const nextUnits = sim.units.map((unit) => {
        const typeDef = UNIT_TYPES[unit.type];
        if (!typeDef || nowTime - unit.lastAttackTime < typeDef.attackCooldown) {
          return unit;
        }

        let bestMonster = null;

        if (typeDef.targetMode === 'strongest') {
          let maxHp = -1;
          for (const m of monstersWithPos) {
            const dist = getDistance(unit.x, unit.y, m.mx, m.my);
            if (dist <= typeDef.sight * Math.SQRT2 && m.hp > maxHp) {
              maxHp = m.hp;
              bestMonster = m;
            }
          }
        } else {
          let minDistance = Infinity;
          for (const m of monstersWithPos) {
            const dist = getDistance(unit.x, unit.y, m.mx, m.my);
            if (dist <= typeDef.sight * Math.SQRT2 && dist < minDistance) {
              minDistance = dist;
              bestMonster = m;
            }
          }
        }

        if (!bestMonster) return unit;

        if (typeDef.attackMode === 'splash') {
          const splashRange = typeDef.splashRange ?? 1.5;
          for (const m of nextMonsters) {
            const pos = monstersWithPos.find((p) => p.id === m.id);
            if (!pos) continue;
            if (getDistance(bestMonster.mx, bestMonster.my, pos.mx, pos.my) <= splashRange) {
              m.hp -= typeDef.damage * unit.level;
            }
          }
          newAttacks.push({
            id: allocId(),
            mode: 'splash',
            faction: typeDef.faction,
            unitType: unit.type,
            tx: bestMonster.mx,
            ty: bestMonster.my,
            time: nowTime,
          });
        } else {
          const mTarget = nextMonsters.find((m) => m.id === bestMonster.id);
          if (mTarget) mTarget.hp -= typeDef.damage * unit.level;
          newAttacks.push({
            id: allocId(),
            mode: 'single',
            faction: typeDef.faction,
            unitType: unit.type,
            homing: !!typeDef.homing,
            sx: unit.x,
            sy: unit.y,
            tx: bestMonster.mx,
            ty: bestMonster.my,
            time: nowTime,
          });
        }

        return { ...unit, lastAttackTime: nowTime };
      });

      // 3. Remove dead + gold from template.reward
      let goldGained = 0;
      let finalBossKilled = false;
      const survivingMonsters = [];
      for (const m of nextMonsters) {
        if (m.hp <= 0) {
          goldGained += m.reward ?? 2;
          if (m.isFinalBoss) finalBossKilled = true;
        } else {
          survivingMonsters.push(m);
        }
      }

      sim.monsters = survivingMonsters;
      sim.units = nextUnits;
      sim.attacks = [...nextAttacks, ...newAttacks];
      if (goldGained > 0) sim.gold += goldGained;

      if (finalBossKilled) {
        sim.gameOver = 'win';
        flushNow();
        animationFrameId = requestAnimationFrame(loop);
        return;
      }

      // 4. Spawn
      const currentPhase = getCurrentPhase(sim.timeRemaining);
      if (currentPhase.type === 'COMBAT') {
        if (currentPhase.wave <= 4) {
          if (currentTime - sim.lastSpawnTime > 1000) {
            spawnMonsterInto(sim, currentPhase.wave, { isBoss: false });
            sim.lastSpawnTime = currentTime;
            sim.spawnedInWave++;
          }
        }

        // Boss once per combat: W2 Golem, W4 Dragon, W5 Demon (final)
        if (!sim.bossSpawnedForWave && currentPhase.timeInPhase < 1.5) {
          if (currentPhase.wave === 2) {
            spawnMonsterInto(sim, 2, { isBoss: true, bossIndex: 0 });
            sim.bossSpawnedForWave = true;
          } else if (currentPhase.wave === 4) {
            spawnMonsterInto(sim, 4, { isBoss: true, bossIndex: 1 });
            sim.bossSpawnedForWave = true;
          } else if (currentPhase.wave === 5) {
            spawnMonsterInto(sim, 5, { isBoss: true, bossIndex: 2, isFinalBoss: true });
            sim.bossSpawnedForWave = true;
          }
        }
      } else if (currentPhase.type === 'REST') {
        sim.bossSpawnedForWave = false;
      }

      flushToReact(false);

      animationFrameId = requestAnimationFrame(loop);
    };

    animationFrameId = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(animationFrameId);
  }, [enabled, flushToReact, flushNow, spawnMonsterInto]);

  return {
    gold,
    monsters,
    units,
    attacks,
    timeRemaining,
    gameOver,
    buildUnit,
    sellUnit,
    upgradeUnit,
    restartGame,
    currentPhase: getCurrentPhase(timeRemaining),
  };
}
