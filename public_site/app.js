// Arcadia Cup 2027 - Official Web Summary & Live Standings
let tournamentData = null;
let currentTab = 'standings';
let refreshTimer = null;
let countdownSecs = 15;

document.addEventListener('DOMContentLoaded', () => {
  initSplashScreen();
  initApp();
  setupTabs();
  setupRefresh();
});

function initSplashScreen() {
  const overlay = document.getElementById('splashOverlay');
  if (!overlay) return;

  let dismissed = false;
  const dismiss = () => {
    if (dismissed) return;
    dismissed = true;
    overlay.classList.add('hidden');
    setTimeout(() => {
      if (overlay.parentNode) {
        overlay.parentNode.removeChild(overlay);
      }
    }, 900);
  };

  overlay.addEventListener('click', dismiss);
  overlay.addEventListener('touchstart', dismiss, { passive: true });
  setTimeout(dismiss, 1900);
}

async function initApp() {
  await fetchTournamentData();
  startAutoRefresh();
}

async function fetchTournamentData(isManual = false) {
  const refreshBtn = document.getElementById('refreshBtn');
  const refreshText = document.getElementById('refreshText');
  const lastUpdatedEl = document.getElementById('lastUpdated');

  if (refreshBtn) refreshBtn.disabled = true;
  if (refreshText) refreshText.textContent = 'UPDATING...';

  try {
    // Try live API first, fallback to static JSON
    let response;
    try {
      response = await fetch('/api/publication', { cache: 'no-store' });
      if (!response.ok) throw new Error('API not available');
    } catch (_) {
      response = await fetch('tournament_data.json', { cache: 'no-store' });
    }

    if (!response.ok) throw new Error('Failed to load tournament data');
    tournamentData = await response.json();

    renderAll();

    const now = new Date();
    if (lastUpdatedEl) {
      lastUpdatedEl.textContent = `Updated ${now.toLocaleTimeString()}`;
    }
  } catch (err) {
    console.error('Error fetching tournament data:', err);
    if (lastUpdatedEl) lastUpdatedEl.textContent = 'Sync issue. Retrying...';
  } finally {
    if (refreshBtn) refreshBtn.disabled = false;
    if (refreshText) refreshText.textContent = 'REFRESH LIVE RESULTS';
    countdownSecs = 15;
  }
}

function startAutoRefresh() {
  if (refreshTimer) clearInterval(refreshTimer);
  refreshTimer = setInterval(() => {
    countdownSecs--;
    const countdownEl = document.getElementById('countdownLabel');
    if (countdownEl) countdownEl.textContent = `(${countdownSecs}s)`;

    if (countdownSecs <= 0) {
      fetchTournamentData();
    }
  }, 1000);
}

function setupRefresh() {
  const refreshBtn = document.getElementById('refreshBtn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      fetchTournamentData(true);
    });
  }
}

function setupTabs() {
  const tabButtons = document.querySelectorAll('.tab-btn');

  function activateTab(tabId) {
    if (!['standings', 'roster', 'pairings', 'ledger', 'rules'].includes(tabId)) return;
    currentTab = tabId;
    tabButtons.forEach(b => {
      if (b.getAttribute('data-tab') === currentTab) {
        b.classList.add('active');
        b.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
      } else {
        b.classList.remove('active');
      }
    });
    renderTabContent();
  }

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.getAttribute('data-tab');
      window.location.hash = tab;
      activateTab(tab);
    });
  });

  const hash = window.location.hash.replace('#', '');
  if (hash && ['standings', 'roster', 'pairings', 'ledger', 'rules'].includes(hash)) {
    activateTab(hash);
  }
}

function renderAll() {
  if (!tournamentData) return;
  renderBirdiePots();
  renderTabContent();
}

// -------------------------------------------------------------
// BIRDIE POT CARDS RENDERING
// -------------------------------------------------------------
function renderBirdiePots() {
  const potsContainer = document.getElementById('birdiePotsGrid');
  if (!potsContainer || !tournamentData.birdiePots) return;

  const pots = tournamentData.birdiePots;
  const coursePots = pots.coursePots || [];

  let html = '';

  // Course Pots
  coursePots.forEach(cp => {
    html += `
      <div class="pot-card" onclick="openBirdiePotModal('${cp.id}')">
        <div>
          <div class="pot-header">
            <span class="pot-badge">ROUND POT</span>
            <span class="pot-click-hint">DETAILS &rarr;</span>
          </div>
          <div class="pot-amount">$${cp.roundPot.toFixed(2)}</div>
          <div class="pot-name">${cp.courseName}</div>
          <div class="pot-sub">${cp.birdieCount} Birdies • Last: Hole ${cp.lastBirdieHole} (${cp.lastBirdieGolfers.join(', ')})</div>
        </div>
      </div>
    `;
  });

  // Cumulative Trip Pot Card
  html += `
    <div class="pot-card cumulative-card" onclick="openBirdiePotModal('cumulative')">
      <div>
        <div class="pot-header">
          <span class="pot-badge" style="background: rgba(255,215,120,0.3); color: #fff;">GRAND TRIP POT</span>
          <span class="pot-click-hint" style="color: #fff;">DETAILS &rarr;</span>
        </div>
        <div class="pot-amount" style="color: #fff;">$${pots.cumulativeTripPot.toFixed(2)}</div>
        <div class="pot-name">Cumulative Trip Pot</div>
        <div class="pot-sub">Accumulates Across All Rounds • Won on Final Round Hole 18!</div>
      </div>
    </div>
  `;

  potsContainer.innerHTML = html;
}

// -------------------------------------------------------------
// TAB CONTENT ROUTER
// -------------------------------------------------------------
function renderTabContent() {
  const container = document.getElementById('tabContent');
  if (!container || !tournamentData) return;

  if (currentTab === 'standings') {
    renderStandingsTab(container);
  } else if (currentTab === 'roster') {
    renderRosterTab(container);
  } else if (currentTab === 'pairings') {
    renderPairingsTab(container);
  } else if (currentTab === 'ledger') {
    renderBirdieLedgerTab(container);
  } else if (currentTab === 'rules') {
    renderRulesTab(container);
  }
}

// -------------------------------------------------------------
// PLAYERS & ROSTER TAB
// -------------------------------------------------------------
let rosterFilter = 'all';

function setRosterFilter(filter) {
  rosterFilter = filter;
  const container = document.getElementById('tabContent');
  if (container && currentTab === 'roster') {
    renderRosterTab(container);
  }
}

function renderRosterTab(container) {
  if (!tournamentData) return;
  const roster = (tournamentData.tournament && tournamentData.tournament.roster) || [];
  const standings = tournamentData.standings || [];

  const isRound1Finished = tournamentData.isRound1Finished === true ||
    standings.some(s => (s.roundsPlayed || 0) > 0);

  const players = roster.map((p, idx) => {
    const stand = standings.find(s => s.playerId === p.id) || {};
    const hcp = typeof p.handicapIndex === 'number' ? p.handicapIndex : (stand.handicapIndex ?? 10.0);
    const bluffsHcp = p.courseHcpBluffs ?? Math.round(hcp * (137 / 113) + (73.5 - 72.0));
    const southHcp = p.courseHcpSouth ?? Math.round(hcp * (134 / 113) + (72.8 - 72.0));
    const rank = p.rank ?? stand.rank ?? (idx + 1);
    const isCaptain = isRound1Finished && (p.isCaptain ?? (rank <= 4));
    let seed = 'TBD';
    if (isRound1Finished) {
      if (p.seed && p.seed !== 'TBD') {
        seed = p.seed;
      } else if (stand.seed && stand.seed !== 'TBD') {
        seed = stand.seed;
      } else {
        seed = isCaptain ? `Seed #${rank} Captain` : `Draft Pool #${rank}`;
      }
    }
    const nameParts = p.name ? p.name.split(' ') : ['Golfer'];
    const initials = p.initials || nameParts.map(n => n[0]).join('').substring(0, 2).toUpperCase();

    return {
      ...p,
      ...stand,
      id: p.id,
      name: p.name,
      nickname: p.nickname || nameParts[0],
      initials,
      handicapIndex: hcp,
      courseHcpBluffs: bluffsHcp,
      courseHcpSouth: southHcp,
      rank,
      isCaptain,
      seed,
      phone: p.phone || stand.phone || '',
      tee: p.tee || stand.tee || 'Blue',
    };
  });

  const filteredPlayers = players.filter(p => {
    if (!isRound1Finished) return true;
    if (rosterFilter === 'captains') return p.isCaptain;
    if (rosterFilter === 'pool') return !p.isCaptain;
    return true;
  });

  const avgHcp = players.length > 0
    ? (players.reduce((sum, p) => sum + p.handicapIndex, 0) / players.length).toFixed(1)
    : '0.0';

  let html = `
    <div class="roster-header-section">
      <div class="section-header">
        <div>
          <h2 class="section-title">Official Tournament Roster &amp; Profiles</h2>
          <p class="section-sub">8-Player Field • USGA Handicap Indexes • Course Handicaps &amp; Contact Directory</p>
        </div>
      </div>

      <!-- QUICK FIELD STATS STRIP -->
      <div class="roster-stats-strip">
        <div class="stat-pill">
          <span class="stat-pill-label">COMPETING FIELD</span>
          <span class="stat-pill-val">8 Golfers</span>
        </div>
        <div class="stat-pill">
          <span class="stat-pill-label">CAPTAIN SEEDS</span>
          <span class="stat-pill-val ${!isRound1Finished ? 'tbd-val' : ''}">${isRound1Finished ? 'Top 4 (#1–#4)' : 'TBD'}</span>
          ${!isRound1Finished ? '<span class="stat-pill-hint">Determined After Round 1</span>' : ''}
        </div>
        <div class="stat-pill">
          <span class="stat-pill-label">DRAFT POOL</span>
          <span class="stat-pill-val ${!isRound1Finished ? 'tbd-val' : ''}">${isRound1Finished ? 'Seeds #5–#8' : 'TBD'}</span>
          ${!isRound1Finished ? '<span class="stat-pill-hint">Determined After Round 1</span>' : ''}
        </div>
        <div class="stat-pill">
          <span class="stat-pill-label">FIELD AVG HCP</span>
          <span class="stat-pill-val">${avgHcp}</span>
        </div>
      </div>

      <!-- FILTER TABS (All / Captains / Draft Pool) -->
      <div class="roster-filters" role="group" aria-label="Roster Filters">
        <button class="filter-chip ${rosterFilter === 'all' ? 'active' : ''}" onclick="setRosterFilter('all')" type="button">
          All Players (${players.length})
        </button>
        ${isRound1Finished ? `
          <button class="filter-chip ${rosterFilter === 'captains' ? 'active' : ''}" onclick="setRosterFilter('captains')" type="button">
            👑 Captain Seeds (4)
          </button>
          <button class="filter-chip ${rosterFilter === 'pool' ? 'active' : ''}" onclick="setRosterFilter('pool')" type="button">
            🎯 Draft Pool (4)
          </button>
        ` : `
          <span class="filter-tbd-note">⏳ Captain seeds (#1–#4) &amp; draft pool (#5–#8) assigned after Round 1</span>
        `}
      </div>
    </div>

    <!-- PLAYERS GRID -->
    <div class="roster-grid">
  `;

  filteredPlayers.forEach(p => {
    const isCaptain = p.isCaptain;
    const isTbd = p.seed === 'TBD' || !isRound1Finished;
    const badgeClass = isTbd ? 'tbd-badge' : (isCaptain ? 'captain-badge' : 'pool-badge');
    const badgeText = isTbd ? 'Seed: TBD' : p.seed;
    const teeColor = (p.tee || 'Blue').toLowerCase().includes('blue') ? '#1e88e5' : '#e0e0e0';
    const cleanPhone = (p.phone || '').replace(/[^0-9]/g, '');

    html += `
      <article class="player-card ${isCaptain ? 'captain-card' : ''}" onclick="openPlayerModal('${p.id}')" tabindex="0" role="button" aria-label="View profile for ${p.name}">
        <div class="player-card-header">
          <div class="player-avatar-wrap">
            <div class="player-avatar-initials">${p.initials}</div>
            ${isCaptain ? '<span class="captain-crown" title="Seed Captain">👑</span>' : ''}
          </div>

          <div class="player-header-info">
            <div class="player-title-row">
              <h3 class="player-full-name">${p.name}</h3>
              <span class="nickname-badge">"${p.nickname}"</span>
            </div>
            <div class="seed-badge ${badgeClass}">${badgeText}</div>
          </div>
        </div>

        <div class="player-specs-grid">
          <div class="spec-cell">
            <span class="spec-label">USGA HCP INDEX</span>
            <span class="spec-val hcp-val">${p.handicapIndex.toFixed(1)}</span>
          </div>

          <div class="spec-cell">
            <span class="spec-label">PLAYING TEE</span>
            <div class="tee-display">
              <span class="tee-dot" style="background-color: ${teeColor};"></span>
              <span class="spec-val" style="font-size: 1.05rem;">${p.tee} Tees</span>
            </div>
          </div>

          <div class="spec-cell">
            <span class="spec-label">THE BLUFFS HCP</span>
            <span class="spec-val">${p.courseHcpBluffs}</span>
            <span class="spec-sub">Rating 73.5 • Slope 137</span>
          </div>

          <div class="spec-cell">
            <span class="spec-label">SOUTH COURSE HCP</span>
            <span class="spec-val">${p.courseHcpSouth}</span>
            <span class="spec-sub">Rating 72.8 • Slope 134</span>
          </div>
        </div>

        <div class="player-card-footer" onclick="event.stopPropagation()">
          ${p.phone ? `
            <div class="player-contact-actions">
              <a href="tel:${cleanPhone}" class="contact-btn call-btn" title="Call ${p.nickname}">
                <span>📞</span>
                <span>Call</span>
              </a>
              <a href="sms:${cleanPhone}" class="contact-btn text-btn" title="Text ${p.nickname}">
                <span>💬</span>
                <span>Text</span>
              </a>
            </div>
          ` : `
            <div style="font-size: 0.85rem; color: var(--text-muted); font-style: italic;">Contact on file</div>
          `}
          <button type="button" class="view-profile-btn" onclick="openPlayerModal('${p.id}')">
            <span>Scorecard &amp; Stats</span>
            <span>&rarr;</span>
          </button>
        </div>
      </article>
    `;
  });

  html += `
    </div>
  `;

  container.innerHTML = html;
}

// -------------------------------------------------------------
// STANDINGS TAB
// -------------------------------------------------------------
function renderStandingsTab(container) {
  const standings = tournamentData.standings || [];
  const isRound1Finished = tournamentData.isRound1Finished === true ||
    standings.some(s => (s.roundsPlayed || 0) > 0);

  let html = `
    <div class="section-header">
      <div>
        <h2 class="section-title">Cumulative Tournament Standings</h2>
        <p class="section-sub">Click any player to inspect hole-by-hole scorecards, handicap strokes & team point contribution.</p>
      </div>
    </div>

    ${!isRound1Finished ? `
      <div class="standings-notice-card">
        ⛳ <strong>Pre-Tournament Standings:</strong> Official Captain seeds (#1–#4) and Draft Pool positions (#5–#8) are determined by Round 1 scores at Arcadia Bluffs.
      </div>
    ` : ''}

    <div class="table-card">
      <table class="standings-table">
        <thead>
          <tr>
            <th>Rank / Golfer</th>
            <th>Rounds</th>
            <th>Total Stableford</th>
            <th>Birdies</th>
            <th>Gross Avg</th>
            <th>Net Avg</th>
            <th>Draft Status</th>
          </tr>
        </thead>
        <tbody>
  `;

  standings.forEach((player, idx) => {
    const isLeader = isRound1Finished && player.rank === 1;
    const rankClass = isLeader ? 'rank-1' : 'rank-other';
    const rowClass = isLeader ? 'clickable-row leader-row' : 'clickable-row';
    const seedDisplay = isRound1Finished ? (player.seed || `Seed #${player.rank}`) : 'TBD';
    const rankDisplay = isRound1Finished ? player.rank : (idx + 1);

    html += `
      <tr class="${rowClass}" onclick="openPlayerModal('${player.playerId}')">
        <td>
          <div class="player-cell">
            <span class="rank-badge ${rankClass}">${rankDisplay}</span>
            <div>
              <div class="player-name-link">${player.name}</div>
              <span class="player-seed-tag ${!isRound1Finished ? 'tbd-tag' : ''}">${seedDisplay}</span>
            </div>
          </div>
        </td>
        <td><strong>${player.roundsPlayed}</strong></td>
        <td><span class="points-cell">${player.totalPoints} pts</span></td>
        <td><strong style="color: var(--cyan);">${player.birdies}</strong></td>
        <td>${player.grossAvg.toFixed(1)}</td>
        <td>${player.netAvg.toFixed(1)}</td>
        <td><span style="font-weight: 700; color: ${isRound1Finished && player.rank <= 4 ? 'var(--gold-light)' : 'var(--text-muted)'};">${seedDisplay}</span></td>
      </tr>
    `;
  });

  html += `
        </tbody>
      </table>
    </div>

    <div style="margin-top: 14px; padding: 12px 16px; background: rgba(168, 85, 247, 0.1); border: 1px solid rgba(168, 85, 247, 0.3); border-radius: 10px; font-size: 0.86rem; color: #d8b4fe; display: flex; align-items: center; gap: 10px;">
      <span style="font-size: 1.2rem;">⛳</span>
      <div>
        <strong>Regulation Play Only:</strong> Stableford tournament standings and point totals reflect 18-hole regulation courses only. Short courses (e.g., Bootlegger, The Dozen) are excluded from Stableford points and count solely toward the Birdie Pot challenge.
      </div>
    </div>
  `;

  container.innerHTML = html;
}

// -------------------------------------------------------------
// PAIRINGS & TEE TIMES TAB (INCLUDES "TBD BEFORE FINAL ROUND")
// -------------------------------------------------------------
function renderPairingsTab(container) {
  const pairings = tournamentData.pairings || [];

  let html = `
    <div class="section-header">
      <div>
        <h2 class="section-title">Schedule, Tee Times & 2-Man Pairings</h2>
        <p class="section-sub">AI-optimized pairings ensure equal rotation across all 7 other golfers over the trip.</p>
      </div>
    </div>
  `;

  pairings.forEach(round => {
    if (round.isShortCourse) {
      // SPECIAL SHORT COURSE CARD (NO 2-MAN TEAMS, BIRDIE POT ONLY)
      html += `
        <div class="pairing-round-card" style="border: 2px solid #a855f7; background: linear-gradient(145deg, #181028, #100b1e); box-shadow: 0 4px 20px rgba(168, 85, 247, 0.15);">
          <div class="pairing-round-header" style="border-bottom: 1px solid rgba(168, 85, 247, 0.3);">
            <div>
              <div style="display: inline-flex; align-items: center; gap: 6px; background: rgba(168, 85, 247, 0.2); border: 1px solid #a855f7; color: #d8b4fe; padding: 4px 10px; border-radius: 6px; font-size: 0.78rem; font-weight: 900; letter-spacing: 0.08em; text-transform: uppercase; margin-bottom: 6px;">
                ⛳ SHORT COURSE (${round.holeCount || ''} HOLES) &bull; BIRDIE POT ONLY
              </div>
              <div class="pairing-round-title" style="color: #f3e8ff;">${round.title}</div>
              <div class="pairing-meta" style="color: #c084fc;">${round.date} &bull; Birdie Pot Challenge Only (Not Counted in Stableford)</div>
            </div>
          </div>
          <div style="padding: 24px 20px; text-align: center; color: #e9d5ff;">
            <div style="font-size: 2.2rem; margin-bottom: 8px;">💰</div>
            <div style="font-size: 1.15rem; font-weight: 800; color: #fff; margin-bottom: 6px;">Casual Play &bull; Birdie Pot Game Only</div>
            <p style="max-width: 580px; margin: 0 auto; font-size: 0.92rem; color: #d8b4fe; line-height: 1.55;">
              Short courses are played for casual fun and the Birdie Pot challenge ($2/birdie per player). Per tournament rules, no 2-man pairings are assigned and points earned do NOT count towards the Stableford tournament standings.
            </p>
          </div>
        </div>
      `;
    } else if (round.isFinalDraft) {
      // SPECIAL "TBD BEFORE FINAL ROUND" BLANK PAIRING DISPLAY
      html += `
        <div class="tbd-banner-card">
          <div class="tbd-main-banner">${round.banner}</div>
          <h3 style="font-size: 1.4rem; color: #fff; margin-bottom: 8px;">${round.title}</h3>
          <p class="tbd-subtext">${round.bannerSub}</p>

          <div style="background: rgba(0,0,0,0.3); border-radius: 12px; padding: 16px; margin: 16px auto; max-width: 680px; text-align: left;">
            <div style="font-weight: 900; color: var(--gold); font-size: 0.85rem; letter-spacing: 0.08em; text-transform: uppercase; margin-bottom: 8px;">
              Live Selection Draft Order (Seeds #1 through #8):
            </div>
            <ul style="color: var(--text-main); font-size: 0.9rem; padding-left: 20px; line-height: 1.6;">
              ${round.draftRules.map(r => `<li>${r}</li>`).join('')}
            </ul>
          </div>

          <div class="draft-diagram-grid">
            ${round.groups.map(g => `
              <div class="draft-match-box">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                  <strong style="color: var(--cyan);">${g.teeTime}</strong>
                  <span style="font-size: 0.75rem; color: var(--gold); font-weight: 800;">${g.flight}</span>
                </div>
                <div class="draft-slot">
                  <div style="font-size: 0.72rem; color: var(--gold); font-weight: 800;">${g.teamA.name}</div>
                  <div style="font-weight: 700; color: #fff;">${g.teamA.captain}</div>
                  <div style="font-size: 0.82rem; color: var(--text-muted); font-style: italic;">+ ${g.teamA.partner}</div>
                </div>
                <div class="vs-divider">VS</div>
                <div class="draft-slot" style="border-left-color: var(--cyan);">
                  <div style="font-size: 0.72rem; color: var(--cyan); font-weight: 800;">${g.teamB.name}</div>
                  <div style="font-weight: 700; color: #fff;">${g.teamB.captain}</div>
                  <div style="font-size: 0.82rem; color: var(--text-muted); font-style: italic;">+ ${g.teamB.partner}</div>
                </div>
              </div>
            `).join('')}
          </div>
          <div style="margin-top: 18px; font-size: 0.85rem; color: #e57373; font-weight: 700;">
            ⚠️ Final Round Scoring: Modified Stableford (-1 Double Bogey penalty in effect)
          </div>
        </div>
      `;
    } else {
      // PRELIMINARY ROUNDS PAIRINGS
      html += `
        <div class="pairing-round-card">
          <div class="pairing-round-header">
            <div>
              <div class="pairing-round-title">${round.title}</div>
              <div class="pairing-meta">${round.date} • ${round.format}</div>
            </div>
          </div>

          <div class="groups-grid">
            ${round.groups.map(g => `
              <div class="group-box">
                <div class="group-tee-time">
                  <span>⏱ ${g.teeTime}</span>
                  <span style="font-size: 0.8rem; color: var(--text-muted);">Group ${g.groupNumber}</span>
                </div>

                <div class="two-man-team">
                  <div class="team-badge">${g.teamA.name} ${g.teamA.score ? `&bull; ${g.teamA.score} pts` : ''}</div>
                  <div class="team-members">${g.teamA.players.join(' & ')}</div>
                </div>

                <div class="vs-divider">MATCH PLAY &bull; 4-SOME ROTATION</div>

                <div class="two-man-team">
                  <div class="team-badge">${g.teamB.name} ${g.teamB.score ? `&bull; ${g.teamB.score} pts` : ''}</div>
                  <div class="team-members">${g.teamB.players.join(' & ')}</div>
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      `;
    }
  });

  container.innerHTML = html;
}

// -------------------------------------------------------------
// BIRDIE POT LEDGER TAB
// -------------------------------------------------------------
function renderBirdieLedgerTab(container) {
  const pots = tournamentData.birdiePots;
  const ledger = pots.playerLedger || [];
  const events = pots.birdieEvents || [];

  let html = `
    <div class="section-header">
      <div>
        <h2 class="section-title">Birdie Pot Ledger & Balances</h2>
        <p class="section-sub">$2.00 entry per birdie per player across field ($1.00 Round Pot, $1.00 Cumulative Trip Pot).</p>
      </div>
    </div>

    <div class="table-card" style="margin-bottom: 24px;">
      <table class="standings-table">
        <thead>
          <tr>
            <th>Golfer</th>
            <th>Birdies Made</th>
            <th>Dues Contributed</th>
            <th>Pots Won</th>
            <th>Net Cash Balance</th>
          </tr>
        </thead>
        <tbody>
          ${ledger.map(row => `
            <tr>
              <td><strong>${row.name}</strong></td>
              <td><span style="color: var(--cyan); font-weight: 800;">${row.birdiesMade}</span></td>
              <td>$${row.totalDues.toFixed(2)}</td>
              <td style="color: var(--gold-light); font-weight: 800;">$${row.potsWon.toFixed(2)}</td>
              <td>
                <strong style="color: ${row.netBalance >= 0 ? '#4caf50' : '#ef5350'};">
                  ${row.netBalance >= 0 ? '+' : ''}$${row.netBalance.toFixed(2)}
                </strong>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>

    <div class="section-header">
      <div>
        <h3 class="section-title" style="font-size: 1.25rem;">Birdie Timeline & "Last Birdie Standing" Race</h3>
        <p class="section-sub">Latest birdie recorded in each round wins that round's pot; latest birdie of the trip takes the cumulative pot!</p>
      </div>
    </div>

    <div class="table-card">
      <table class="standings-table">
        <thead>
          <tr>
            <th>Round</th>
            <th>Hole</th>
            <th>Golfer</th>
            <th>Score</th>
            <th>Time</th>
            <th>Pot Status</th>
          </tr>
        </thead>
        <tbody>
          ${events.map(e => `
            <tr style="${e.isTripLeader || e.isRoundWinner ? 'background: rgba(213, 174, 91, 0.12);' : ''}">
              <td>${e.round} (${e.course.split(' ')[1] || 'Course'})</td>
              <td><strong>Hole ${e.hole}</strong> (Par ${e.par})</td>
              <td><strong>${e.golfer}</strong></td>
              <td>${e.score}</td>
              <td>${e.time}</td>
              <td>
                ${e.isTripLeader ? '<span class="counted-badge" style="background: var(--gold); color: #000;">🏆 CURRENT TRIP LEADER</span>' : 
                  e.isRoundWinner ? '<span class="counted-badge">WON ROUND POT</span>' : '<span style="color: var(--text-muted); font-size: 0.8rem;">Recorded</span>'}
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>
  `;

  container.innerHTML = html;
}

// -------------------------------------------------------------
// RULES TAB
// -------------------------------------------------------------
function renderRulesTab(container) {
  let html = `
    <div class="section-header">
      <div>
        <h2 class="section-title">Official Tournament Format & Rules</h2>
        <p class="section-sub">Detailed breakdown of scoring, AI pairings, partner draft, and Birdie Pot rules.</p>
      </div>
    </div>

    <div class="rules-container">
      <div class="rule-card">
        <div class="rule-header">
          <div class="rule-num">1</div>
          <div class="rule-title">AI-Driven 4-Somes & Partner Rotation</div>
        </div>
        <p style="color: var(--text-main); margin-bottom: 10px;">
          The 8 golfers are divided into two 4-somes per round. An AI optimization engine maximizes randomness while guaranteeing equal playing time with all 7 other participants over the trip.
        </p>
      </div>

      <div class="rule-card">
        <div class="rule-header">
          <div class="rule-num">2</div>
          <div class="rule-title">2-Man Net Best Ball Stableford (Rounds 1 to N-1)</div>
        </div>
        <p style="color: var(--text-main); margin-bottom: 12px;">
          Within each 4-some, an AI-randomized 2-man team plays a net-adjusted Stableford system. On each hole, the team takes the higher Stableford point score of the two partners.
        </p>
        <table class="points-table">
          <thead>
            <tr><th>Result</th><th>Net Score</th><th>Points Awarded</th></tr>
          </thead>
          <tbody>
            <tr><td>Double Eagle / Albatross</td><td>3 under net</td><td><strong>+5 pts</strong></td></tr>
            <tr><td>Eagle</td><td>2 under net</td><td><strong>+4 pts</strong></td></tr>
            <tr><td>Birdie</td><td>1 under net</td><td><strong>+3 pts</strong></td></tr>
            <tr><td>Par</td><td>Even net</td><td><strong>+2 pts</strong></td></tr>
            <tr><td>Bogey</td><td>1 over net</td><td><strong>+1 pt</strong></td></tr>
            <tr><td>Double Bogey or worse</td><td>2+ over net</td><td><strong>0 pts (Max 0)</strong></td></tr>
          </tbody>
        </table>
      </div>

      <div class="rule-card">
        <div class="rule-header">
          <div class="rule-num">3</div>
          <div class="rule-title">End of Round Scoring Credit</div>
        </div>
        <p style="color: var(--text-main);">
          Both players on the 2-man team are credited with the team's total Stableford points for their cumulative tournament standing. If a team shoots 45 points, each teammate records 45 points.
        </p>
      </div>

      <div class="rule-card">
        <div class="rule-header">
          <div class="rule-num">4</div>
          <div class="rule-title">Final Round Selection Draft (#1 to #8)</div>
        </div>
        <p style="color: var(--text-main); margin-bottom: 8px;">
          Entering the final round, cumulative points are ranked from #1 to #8:
        </p>
        <ul style="padding-left: 20px; color: var(--text-muted); line-height: 1.6;">
          <li><strong style="color: var(--gold);">#1 Seed Captain:</strong> Chooses first from #5, #6, #7, or #8.</li>
          <li><strong style="color: var(--gold);">#2 Seed Captain:</strong> Chooses next from the remaining 3 players.</li>
          <li><strong style="color: var(--gold);">#3 Seed Captain:</strong> Chooses next from the remaining 2 players.</li>
          <li><strong style="color: var(--gold);">#4 Seed Captain:</strong> Paired with the final remaining player.</li>
        </ul>
      </div>

      <div class="rule-card">
        <div class="rule-header">
          <div class="rule-num" style="background: #e57373; color: #fff;">5</div>
          <div class="rule-title">Final Round Modified Stableford (Penalty Scoring)</div>
        </div>
        <p style="color: var(--text-main); margin-bottom: 12px;">
          The final championship round institutes penalties for bad holes to ramp up the drama:
        </p>
        <table class="points-table">
          <thead>
            <tr><th>Result</th><th>Net Score</th><th>Points Awarded</th></tr>
          </thead>
          <tbody>
            <tr><td>Double Bogey or worse</td><td>2+ over net</td><td><strong style="color: #ef5350;">-1 pt (Penalty)</strong></td></tr>
            <tr><td>Bogey</td><td>1 over net</td><td><strong>0 pts</strong></td></tr>
            <tr><td>Par</td><td>Even net</td><td><strong>+1 pt</strong></td></tr>
            <tr><td>Birdie</td><td>1 under net</td><td><strong style="color: var(--cyan);">+2 pts</strong></td></tr>
            <tr><td>Eagle</td><td>2 under net</td><td><strong style="color: var(--gold);">+3 pts</strong></td></tr>
          </tbody>
        </table>
      </div>

      <div class="rule-card">
        <div class="rule-header">
          <div class="rule-num" style="background: var(--gold); color: #000;">💰</div>
          <div class="rule-title">The Birdie Pot Game Rules</div>
        </div>
        <p style="color: var(--text-main); line-height: 1.6;">
          • <strong>$2.00 / Birdie:</strong> For every birdie made in the round across all 8 golfers, every player owes $2.00.<br/>
          • <strong>50/50 Split:</strong> $1.00 goes to that Round's Pot, $1.00 goes to the Cumulative Trip Pot.<br/>
          • <strong>Round Pot Winner:</strong> The player with the LAST birdie made in that round wins the entire round pot!<br/>
          • <strong>Cumulative Trip Pot Winner:</strong> The player with the LAST birdie made of the trip wins the entire accumulated trip pot!<br/>
          • <strong>Ties:</strong> If multiple players birdie that same last hole, the pot is divided equally.
        </p>
      </div>
    </div>
  `;

  container.innerHTML = html;
}

// -------------------------------------------------------------
// -------------------------------------------------------------
// MODALS
// -------------------------------------------------------------
function openPlayerModal(playerId) {
  if (!tournamentData) return;
  const standings = tournamentData.standings || [];
  const roster = (tournamentData.tournament && tournamentData.tournament.roster) || [];

  const sPlayer = standings.find(p => p.playerId === playerId || p.id === playerId) || {};
  const rPlayer = roster.find(p => p.id === playerId || p.playerId === playerId) || {};

  if (!sPlayer.playerId && !rPlayer.id) return;

  const name = rPlayer.name || sPlayer.name || 'Golfer';
  const nameParts = name.split(' ');
  const nickname = rPlayer.nickname || sPlayer.nickname || nameParts[0];
  const hcp = typeof rPlayer.handicapIndex === 'number' ? rPlayer.handicapIndex : (sPlayer.handicapIndex ?? 10.0);
  const bluffsHcp = rPlayer.courseHcpBluffs ?? Math.round(hcp * (137 / 113) + (73.5 - 72.0));
  const southHcp = rPlayer.courseHcpSouth ?? Math.round(hcp * (134 / 113) + (72.8 - 72.0));
  const rank = sPlayer.rank ?? rPlayer.rank ?? 1;
  const isRound1Finished = tournamentData.isRound1Finished === true ||
    ((tournamentData.standings || []).some(s => (s.roundsPlayed || 0) > 0));
  const isCaptain = isRound1Finished && (rank <= 4);
  let seed = 'Seed: TBD';
  if (isRound1Finished) {
    seed = (sPlayer.seed && sPlayer.seed !== 'TBD') ? sPlayer.seed :
           ((rPlayer.seed && rPlayer.seed !== 'TBD') ? rPlayer.seed :
           (isCaptain ? `Seed #${rank} Captain` : `Draft Pool #${rank}`));
  }
  const tee = rPlayer.tee || sPlayer.tee || 'Blue';
  const phone = rPlayer.phone || sPlayer.phone || '';
  const cleanPhone = phone.replace(/[^0-9]/g, '');
  const initials = rPlayer.initials || sPlayer.initials || nameParts.map(n => n[0]).join('').substring(0, 2).toUpperCase();

  const totalPoints = sPlayer.totalPoints ?? 0;
  const birdies = sPlayer.birdies ?? 0;
  const grossAvg = sPlayer.grossAvg ?? 0.0;
  const netAvg = sPlayer.netAvg ?? 0.0;
  const contributionPct = sPlayer.contributionPct ?? 50;
  const partnerHistory = sPlayer.partnerHistory || [];
  const roundsPlayed = sPlayer.roundsPlayed ?? 0;

  const modalContainer = document.getElementById('modalContainer');
  const sampleCard = tournamentData.sampleScorecards && (tournamentData.sampleScorecards[playerId] || tournamentData.sampleScorecards[sPlayer.playerId]);

  let modalHtml = `
    <div class="modal-overlay" onclick="closeModal(event)">
      <div class="modal-content" onclick="event.stopPropagation()">
        <button class="modal-close" onclick="closeModal()">&times;</button>

        <div style="display: flex; align-items: center; gap: 16px; margin-bottom: 20px; flex-wrap: wrap;">
          <div class="player-avatar-wrap" style="width: 64px; height: 64px;">
            <div class="player-avatar-initials" style="font-size: 1.4rem;">${initials}</div>
            ${isCaptain ? '<span class="captain-crown" style="font-size: 1.2rem;">👑</span>' : ''}
          </div>
          <div>
            <div style="display: flex; align-items: baseline; gap: 8px;">
              <h2 style="font-size: 1.6rem; color: #fff; line-height: 1.2;">${name}</h2>
              <span class="nickname-badge" style="font-size: 1rem;">"${nickname}"</span>
            </div>
            <div style="color: var(--cyan); font-weight: 800; font-size: 0.9rem; margin-top: 2px;">
              ${seed} &bull; ${tee} Tees
            </div>
          </div>
        </div>

        <!-- COURSE HANDICAPS STRIP -->
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 10px; margin-bottom: 20px;">
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; border: 1px solid var(--line); text-align: center;">
            <div style="font-size: 0.7rem; color: var(--text-muted); font-weight: 800;">USGA HCP INDEX</div>
            <div style="font-size: 1.4rem; font-weight: 900; color: var(--gold-light);">${hcp.toFixed(1)}</div>
          </div>
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; border: 1px solid var(--line); text-align: center;">
            <div style="font-size: 0.7rem; color: var(--text-muted); font-weight: 800;">THE BLUFFS HCP</div>
            <div style="font-size: 1.4rem; font-weight: 900; color: #fff;">${bluffsHcp}</div>
            <div style="font-size: 0.68rem; color: var(--text-muted);">Slope 137</div>
          </div>
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; border: 1px solid var(--line); text-align: center;">
            <div style="font-size: 0.7rem; color: var(--text-muted); font-weight: 800;">SOUTH COURSE HCP</div>
            <div style="font-size: 1.4rem; font-weight: 900; color: #fff;">${southHcp}</div>
            <div style="font-size: 0.68rem; color: var(--text-muted);">Slope 134</div>
          </div>
        </div>

        ${phone ? `
          <div style="background: rgba(82, 227, 150, 0.08); border: 1px solid rgba(82, 227, 150, 0.3); border-radius: 10px; padding: 12px 16px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
            <div>
              <div style="font-size: 0.72rem; color: #52e396; font-weight: 800; text-transform: uppercase;">PLAYER CONTACT DIRECTORY</div>
              <div style="font-size: 1rem; font-weight: 800; color: #fff;">${phone}</div>
            </div>
            <div style="display: flex; gap: 8px;">
              <a href="tel:${cleanPhone}" class="contact-btn call-btn">📞 Call</a>
              <a href="sms:${cleanPhone}" class="contact-btn text-btn">💬 SMS</a>
            </div>
          </div>
        ` : ''}

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(110px, 1fr)); gap: 10px; margin-bottom: 22px;">
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; text-align: center; border: 1px solid var(--line);">
            <div style="font-size: 0.72rem; color: var(--text-muted);">TOTAL POINTS</div>
            <div style="font-size: 1.3rem; font-weight: 900; color: var(--gold-light);">${totalPoints} pts</div>
          </div>
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; text-align: center; border: 1px solid var(--line);">
            <div style="font-size: 0.72rem; color: var(--text-muted);">BIRDIES</div>
            <div style="font-size: 1.3rem; font-weight: 900; color: var(--cyan);">${birdies}</div>
          </div>
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; text-align: center; border: 1px solid var(--line);">
            <div style="font-size: 0.72rem; color: var(--text-muted);">GROSS AVG</div>
            <div style="font-size: 1.3rem; font-weight: 900; color: #fff;">${roundsPlayed > 0 ? grossAvg.toFixed(1) : '-'}</div>
          </div>
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; text-align: center; border: 1px solid var(--line);">
            <div style="font-size: 0.72rem; color: var(--text-muted);">TEAM CONTRIB</div>
            <div style="font-size: 1.3rem; font-weight: 900; color: #81c784;">${roundsPlayed > 0 ? contributionPct + '%' : '-'}</div>
          </div>
        </div>

        ${partnerHistory.length > 0 ? `
          <h3 style="font-size: 1.15rem; color: #fff; margin-bottom: 8px;">2-Man Team Partner History & Contribution</h3>
          <div style="background: var(--bg-card); padding: 14px; border-radius: 10px; border: 1px solid var(--line); margin-bottom: 20px;">
            <ul style="color: var(--text-main); font-size: 0.9rem; padding-left: 18px; line-height: 1.6;">
              ${partnerHistory.map(h => `<li>${h}</li>`).join('')}
            </ul>
          </div>
        ` : `
          <div style="background: var(--bg-card); padding: 14px; border-radius: 10px; border: 1px solid var(--line); margin-bottom: 20px; font-size: 0.88rem; color: var(--text-muted);">
            ⛳ <strong>Tournament Preview:</strong> 2-Man partner pairings and hole-by-hole Stableford scoring will update live once Round 1 begins at Arcadia Bluffs!
          </div>
        `}
  `;

  if (sampleCard) {
    modalHtml += `
      <h3 style="font-size: 1.15rem; color: #fff; margin-bottom: 6px;">Hole-by-Hole Scorecard — ${sampleCard.course}</h3>
      <p style="font-size: 0.8rem; color: var(--text-muted); margin-bottom: 10px;">
        <span class="stroke-highlight" style="padding: 2px 6px; border-radius: 4px;">Yellow net cells</span> indicate holes where handicap stroke was received.
      </p>

      <div style="overflow-x: auto; margin-bottom: 14px;">
        <table class="scorecard-mini-table">
          <thead>
            <tr><th>Hole</th><th>1</th><th>2</th><th>3</th><th>4</th><th>5</th><th>6</th><th>7</th><th>8</th><th>9</th><th>OUT</th></tr>
          </thead>
          <tbody>
            <tr><td>Par</td>${sampleCard.front9.map(h => `<td>${h.par}</td>`).join('')}<td>36</td></tr>
            <tr><td>Gross</td>${sampleCard.front9.map(h => `<td><strong>${h.gross}</strong></td>`).join('')}<td>${sampleCard.front9.reduce((a,c)=>a+c.gross,0)}</td></tr>
            <tr><td>Net</td>${sampleCard.front9.map(h => `<td class="${h.strokes ? 'stroke-highlight' : ''}">${h.net}</td>`).join('')}<td>${sampleCard.front9.reduce((a,c)=>a+c.net,0)}</td></tr>
            <tr><td>Pts</td>${sampleCard.front9.map(h => `<td style="color: var(--gold-light); font-weight: 800;">${h.points}</td>`).join('')}<td>${sampleCard.front9.reduce((a,c)=>a+c.points,0)}</td></tr>
          </tbody>
        </table>
      </div>

      <div style="overflow-x: auto; margin-bottom: 18px;">
        <table class="scorecard-mini-table">
          <thead>
            <tr><th>Hole</th><th>10</th><th>11</th><th>12</th><th>13</th><th>14</th><th>15</th><th>16</th><th>17</th><th>18</th><th>IN</th><th>TOT</th></tr>
          </thead>
          <tbody>
            <tr><td>Par</td>${sampleCard.back9.map(h => `<td>${h.par}</td>`).join('')}<td>36</td><td>72</td></tr>
            <tr><td>Gross</td>${sampleCard.back9.map(h => `<td><strong>${h.gross}</strong></td>`).join('')}<td>${sampleCard.back9.reduce((a,c)=>a+c.gross,0)}</td><td>${sampleCard.front9.reduce((a,c)=>a+c.gross,0)+sampleCard.back9.reduce((a,c)=>a+c.gross,0)}</td></tr>
            <tr><td>Net</td>${sampleCard.back9.map(h => `<td class="${h.strokes ? 'stroke-highlight' : ''}">${h.net}</td>`).join('')}<td>${sampleCard.back9.reduce((a,c)=>a+c.net,0)}</td><td>${sampleCard.front9.reduce((a,c)=>a+c.net,0)+sampleCard.back9.reduce((a,c)=>a+c.net,0)}</td></tr>
            <tr><td>Pts</td>${sampleCard.back9.map(h => `<td style="color: var(--gold-light); font-weight: 800;">${h.points}</td>`).join('')}<td>${sampleCard.back9.reduce((a,c)=>a+c.points,0)}</td><td style="color: var(--gold-light); font-weight: 900;">${sampleCard.front9.reduce((a,c)=>a+c.points,0)+sampleCard.back9.reduce((a,c)=>a+c.points,0)}</td></tr>
          </tbody>
        </table>
      </div>
    `;
  }

  modalHtml += `
      </div>
    </div>
  `;

  modalContainer.innerHTML = modalHtml;
}

function openBirdiePotModal(potId) {
  const pots = tournamentData.birdiePots;
  if (!pots) return;

  const modalContainer = document.getElementById('modalContainer');
  const isCumulative = potId === 'cumulative';
  const coursePot = (pots.coursePots || []).find(p => p.id === potId);

  let title = isCumulative ? 'Cumulative Trip Birdie Pot' : `${coursePot.courseName} Round Pot`;
  let amount = isCumulative ? pots.cumulativeTripPot : coursePot.roundPot;
  let status = isCumulative 
    ? 'Accumulating across all 4 rounds. The LAST birdie of the entire trip takes this pot!'
    : `Awarded to the player with the latest birdie in Round ${coursePot.roundNumber}.`;

  let html = `
    <div class="modal-overlay" onclick="closeModal(event)">
      <div class="modal-content" onclick="event.stopPropagation()">
        <button class="modal-close" onclick="closeModal()">&times;</button>

        <div style="margin-bottom: 20px; border-bottom: 1px solid var(--line); padding-bottom: 16px;">
          <span class="pot-badge">${isCumulative ? 'TRIP CUMULATIVE PURSE' : 'ROUND PURSE'}</span>
          <h2 style="font-size: 1.8rem; color: var(--gold-light); margin: 6px 0;">${title}</h2>
          <div style="font-size: 2.2rem; font-weight: 900; color: #fff;">$${amount.toFixed(2)}</div>
          <p style="color: var(--text-muted); font-size: 0.9rem; margin-top: 6px;">${status}</p>
        </div>

        <h3 style="font-size: 1.15rem; color: #fff; margin-bottom: 8px;">Birdie Timeline in this Competition</h3>
        <div style="max-height: 280px; overflow-y: auto; background: var(--bg-card); border-radius: 10px; border: 1px solid var(--line); margin-bottom: 18px;">
          <table class="standings-table" style="min-width: 100%;">
            <thead>
              <tr><th>Hole</th><th>Golfer</th><th>Score</th><th>Status</th></tr>
            </thead>
            <tbody>
              ${pots.birdieEvents.map(e => `
                <tr style="${e.isTripLeader || (coursePot && e.round === coursePot.roundNumber && e.isRoundWinner) ? 'background: rgba(213, 174, 91, 0.15);' : ''}">
                  <td>Hole ${e.hole} (${e.course.split(' ')[1] || 'Course'})</td>
                  <td><strong>${e.golfer}</strong></td>
                  <td>${e.score}</td>
                  <td>
                    ${e.isTripLeader ? '<span class="counted-badge" style="background: var(--gold); color: #000;">🏆 CURRENT TRIP WINNER</span>' : 
                      (coursePot && e.round === coursePot.roundNumber && e.isRoundWinner) ? '<span class="counted-badge">WON ROUND POT</span>' : 'Birdie recorded'}
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>

        <div style="background: rgba(0,0,0,0.3); padding: 14px; border-radius: 8px; font-size: 0.85rem; color: var(--text-muted);">
          💡 <strong>Tiebreaker Rule:</strong> If 2 or more golfers record a birdie on that exact same last hole, the pot is divided equally among those winners.
        </div>
      </div>
    </div>
  `;

  modalContainer.innerHTML = html;
}

function closeModal(event) {
  if (event && event.target && !event.target.classList.contains('modal-overlay') && !event.target.classList.contains('modal-close')) {
    return;
  }
  const modalContainer = document.getElementById('modalContainer');
  if (modalContainer) modalContainer.innerHTML = '';
}
