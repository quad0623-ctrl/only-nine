import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useGameEngine, MAX_MONSTERS } from './hooks/useGameEngine';
import { FACTIONS, UNIT_TYPES, UNIT_KEYS_BY_FACTION } from './data/units';
import { GameBoard } from './components/GameBoard';
import './App.css';

function App() {
  const { t, i18n } = useTranslation();
  const [started, setStarted] = useState(false);
  const [selectedAction, setSelectedAction] = useState(null);
  const [factionTab, setFactionTab] = useState('LUMINA');

  const changeLanguage = (lng) => {
    i18n.changeLanguage(lng);
  };

  const {
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
    currentPhase,
  } = useGameEngine({ enabled: started });

  const handleBuild = (x, y, type) => {
    buildUnit(x, y, type);
    setSelectedAction(null);
  };

  const handleRestart = () => {
    restartGame();
    setSelectedAction(null);
  };

  const phaseLabel =
    currentPhase?.type === 'REST'
      ? t('phase_rest')
      : currentPhase?.type === 'COMBAT'
        ? t('phase_combat')
        : currentPhase?.type;

  const languageSelector = (
    <div
      className="language-selector"
      style={{ position: 'absolute', top: '10px', right: '10px', display: 'flex', gap: '5px', zIndex: 20 }}
    >
      <button type="button" onClick={() => changeLanguage('ko')}>한국어</button>
      <button type="button" onClick={() => changeLanguage('en')}>EN</button>
      <button type="button" onClick={() => changeLanguage('zh')}>中文</button>
      <button type="button" onClick={() => changeLanguage('ja')}>日本語</button>
    </div>
  );

  if (!started) {
    return (
      <div className="app-container">
        {languageSelector}
        <div className="screen-overlay">
          <h1 className="title">{t('title')}</h1>
          <button className="btn-primary" onClick={() => setStarted(true)}>
            {t('game_start')}
          </button>
        </div>
      </div>
    );
  }

  const factionUnitKeys = UNIT_KEYS_BY_FACTION[factionTab] ?? [];

  return (
    <div className="app-container">
      {languageSelector}
      <div className="hud">
        <div className="stat-box">
          <span className="stat-label">{t('gold')}</span>
          <span className="stat-value gold-text">{gold}</span>
        </div>
        <div className="stat-box">
          <span className="stat-label">
            {t('wave')} {currentPhase?.wave || 1} ({phaseLabel})
          </span>
          <span className="stat-value time-text">{timeRemaining}s</span>
        </div>
        <div className="stat-box">
          <span className="stat-label">{t('monsters')}</span>
          <span className="stat-value monster-text">{monsters.length} / {MAX_MONSTERS}</span>
        </div>
      </div>

      <div className="game-area">
        <GameBoard
          monsters={monsters}
          units={units}
          attacks={attacks}
          onBuild={handleBuild}
          onSell={sellUnit}
          onUpgrade={upgradeUnit}
          selectedAction={selectedAction}
        />
      </div>

      <div className="build-menu">
        <div className="faction-tabs">
          {Object.keys(FACTIONS).map((factionId) => {
            const faction = FACTIONS[factionId];
            return (
              <button
                key={factionId}
                type="button"
                className={`faction-tab ${factionTab === factionId ? 'active' : ''}`}
                style={{ '--faction-color': faction.color }}
                onClick={() => setFactionTab(factionId)}
              >
                {t(faction.nameKey)}
              </button>
            );
          })}
        </div>

        <div className="build-row">
          {factionUnitKeys.map((key) => {
            const type = UNIT_TYPES[key];
            const isSelected = selectedAction === key;
            const canAfford = gold >= type.cost;
            return (
              <button
                key={key}
                type="button"
                className={`build-btn faction-${type.faction.toLowerCase()} ${isSelected ? 'selected' : ''}`}
                disabled={!canAfford && !isSelected}
                onClick={() => setSelectedAction(isSelected ? null : key)}
              >
                <div
                  className="btn-icon"
                  style={{
                    background: FACTIONS[type.faction].color,
                    color: '#0a0a12',
                  }}
                >
                  {type.icon}
                </div>
                <span className="btn-name">{t(type.nameKey)}</span>
                <span className="btn-cost">{type.cost} G</span>
              </button>
            );
          })}

          <button
            type="button"
            className={`build-btn ${selectedAction === 'UPGRADE' ? 'selected' : ''}`}
            onClick={() => setSelectedAction(selectedAction === 'UPGRADE' ? null : 'UPGRADE')}
          >
            <div className="btn-icon" style={{ backgroundColor: '#a855f7' }}>
              ↑
            </div>
            <span className="btn-name">{t('upgrade')}</span>
          </button>

          <button
            type="button"
            className={`build-btn ${selectedAction === 'SELL' ? 'selected sell-selected' : 'sell-btn'}`}
            onClick={() => setSelectedAction(selectedAction === 'SELL' ? null : 'SELL')}
          >
            <div
              className="btn-icon"
              style={{ background: selectedAction === 'SELL' ? '#ef4444' : '#b91c1c' }}
            >
              ×
            </div>
            <span className="btn-name">{t('sell')}</span>
            <span className="btn-cost">{t('refund')}</span>
          </button>
        </div>
      </div>

      {gameOver && (
        <div className="screen-overlay">
          <h1
            className="title"
            style={{
              background:
                gameOver === 'win'
                  ? 'linear-gradient(to right, #22c55e, #10b981)'
                  : 'linear-gradient(to right, #ef4444, #f97316)',
            }}
          >
            {gameOver === 'win' ? t('victory') : t('game_over')}
          </h1>
          <button className="btn-primary" onClick={handleRestart}>
            {t('play_again')}
          </button>
        </div>
      )}
    </div>
  );
}

export default App;
