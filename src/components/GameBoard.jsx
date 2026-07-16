import { TRACK_PATH } from '../hooks/useGameEngine';
import { FACTIONS, UNIT_TYPES } from '../data/units';

export function GameBoard({ monsters, units, attacks = [], onBuild, onSell, onUpgrade, selectedAction }) {
  const cells = [];

  for (let y = 0; y < 5; y++) {
    for (let x = 0; x < 5; x++) {
      const isTrack = x === 0 || x === 4 || y === 0 || y === 4;
      const isBase = !isTrack;
      const cellUnit = units.find((u) => u.x === x && u.y === y);
      const unitDef = cellUnit ? UNIT_TYPES[cellUnit.type] : null;
      const faction = unitDef ? FACTIONS[unitDef.faction] : null;

      cells.push(
        <div
          key={`${x}-${y}`}
          className={`grid-cell ${isTrack ? 'track' : 'base'}`}
          onClick={() => {
            if (isBase) {
              if (cellUnit && selectedAction === 'SELL') {
                onSell(x, y);
              } else if (cellUnit && selectedAction === 'UPGRADE') {
                onUpgrade(x, y);
              } else if (
                !cellUnit &&
                selectedAction &&
                selectedAction !== 'SELL' &&
                selectedAction !== 'UPGRADE'
              ) {
                onBuild(x, y, selectedAction);
              }
            }
          }}
        >
          {cellUnit && unitDef && (
            <div
              className={`unit unit-faction-${unitDef.faction.toLowerCase()}`}
              style={{
                background: faction?.color,
                boxShadow: `0 0 12px ${faction?.color}`,
              }}
            >
              {unitDef.icon}
              <div className="unit-level-badge">Lv.{cellUnit.level}</div>
            </div>
          )}
        </div>
      );
    }
  }

  return (
    <div className="grid-container">
      {cells}

      <div className="entity-layer">
        {monsters.map((m) => {
          const index = Math.floor(m.progress) % 16;
          const nextIndex = (index + 1) % 16;
          const fraction = m.progress - Math.floor(m.progress);

          const p1 = TRACK_PATH[index];
          const p2 = TRACK_PATH[nextIndex] ?? TRACK_PATH[15];
          const mx = p1.x + (p2.x - p1.x) * fraction;
          const my = p1.y + (p2.y - p1.y) * fraction;

          return (
            <div
              key={m.id}
              className={`monster ${m.isBoss ? 'boss' : ''}`}
              style={{
                left: `${mx * 20}%`,
                top: `${my * 20}%`,
                width: m.isBoss ? '30%' : '20%',
                height: m.isBoss ? '30%' : '20%',
                transform: m.isBoss ? 'translate(-15%, -15%)' : 'translate(0, 0)',
              }}
            >
              <div
                className="monster-body"
                style={{
                  borderColor: m.color,
                  boxShadow: `0 0 15px ${m.color}, inset 0 0 10px ${m.color}`,
                }}
              />
              <div className="hp-bar-bg">
                <div className="hp-bar-fill" style={{ width: `${(m.hp / m.maxHp) * 100}%` }} />
              </div>
            </div>
          );
        })}

        {attacks.map((attack) => {
          const factionColor = FACTIONS[attack.faction]?.color ?? '#00f0ff';

          if (attack.mode === 'splash') {
            return (
              <div
                key={attack.id}
                className="attack-splash"
                style={{
                  left: `${attack.tx * 20 + 10}%`,
                  top: `${attack.ty * 20 + 10}%`,
                  background: `radial-gradient(circle, ${factionColor}cc 0%, transparent 70%)`,
                }}
              />
            );
          }

          const dx = (attack.tx - attack.sx) * 20;
          const dy = (attack.ty - attack.sy) * 20;
          const distance = Math.sqrt(dx * dx + dy * dy);
          const angle = (Math.atan2(dy, dx) * 180) / Math.PI;
          return (
            <div
              key={attack.id}
              className={`attack-projectile ${attack.homing ? 'attack-homing' : ''}`}
              style={{
                left: `${attack.sx * 20 + 10}%`,
                top: `${attack.sy * 20 + 10}%`,
                width: `${distance}%`,
                transform: `rotate(${angle}deg)`,
                background: factionColor,
                boxShadow: `0 0 10px ${factionColor}`,
              }}
            />
          );
        })}
      </div>
    </div>
  );
}
