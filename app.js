// Arcadia Cup 2027 - Official Web Summary & Live Standings
let tournamentData = null;
let currentTab = 'standings';
let refreshTimer = null;
let countdownSecs = 15;

document.addEventListener('DOMContentLoaded', () => {
  initApp();
  setupTabs();
  setupRefresh();
});

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
  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      tabButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentTab = btn.getAttribute('data-tab');
      renderTabContent();
    });
  });
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
  } else if (currentTab === 'pairings') {
    renderPairingsTab(container);
  } else if (currentTab === 'ledger') {
    renderBirdieLedgerTab(container);
  } else if (currentTab === 'rules') {
    renderRulesTab(container);
  }
}

// -------------------------------------------------------------
// STANDINGS TAB
// -------------------------------------------------------------
function renderStandingsTab(container) {
  const standings = tournamentData.standings || [];

  let html = `
    <div class="section-header">
      <div>
        <h2 class="section-title">Cumulative Tournament Standings</h2>
        <p class="section-sub">Click any player to inspect hole-by-hole scorecards, handicap strokes & team point contribution.</p>
      </div>
    </div>

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

  standings.forEach(player => {
    const isLeader = player.rank === 1;
    const rankClass = isLeader ? 'rank-1' : 'rank-other';
    const rowClass = isLeader ? 'clickable-row leader-row' : 'clickable-row';

    html += `
      <tr class="${rowClass}" onclick="openPlayerModal('${player.playerId}')">
        <td>
          <div class="player-cell">
            <span class="rank-badge ${rankClass}">${player.rank}</span>
            <div>
              <div class="player-name-link">${player.name}</div>
              <span class="player-seed-tag">${player.seed}</span>
            </div>
          </div>
        </td>
        <td><strong>${player.roundsPlayed}</strong></td>
        <td><span class="points-cell">${player.totalPoints} pts</span></td>
        <td><strong style="color: var(--cyan);">${player.birdies}</strong></td>
        <td>${player.grossAvg.toFixed(1)}</td>
        <td>${player.netAvg.toFixed(1)}</td>
        <td><span style="font-weight: 700; color: ${player.rank <= 4 ? 'var(--gold-light)' : 'var(--text-muted)'};">${player.seed}</span></td>
      </tr>
    `;
  });

  html += `
        </tbody>
      </table>
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
    if (round.isFinalDraft) {
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
// MODALS
// -------------------------------------------------------------
function openPlayerModal(playerId) {
  const standings = tournamentData.standings || [];
  const player = standings.find(p => p.playerId === playerId);
  if (!player) return;

  const modalContainer = document.getElementById('modalContainer');
  const sampleCard = tournamentData.sampleScorecards && tournamentData.sampleScorecards[playerId];

  let modalHtml = `
    <div class="modal-overlay" onclick="closeModal(event)">
      <div class="modal-content" onclick="event.stopPropagation()">
        <button class="modal-close" onclick="closeModal()">&times;</button>

        <div style="display: flex; align-items: center; gap: 16px; margin-bottom: 20px;">
          <img src="assets/arcadia_cup_crest.jpg" style="width: 60px; height: 60px; border-radius: 50%; border: 2px solid var(--gold); object-fit: cover;">
          <div>
            <h2 style="font-size: 1.6rem; color: #fff;">${player.name}</h2>
            <div style="color: var(--cyan); font-weight: 800; font-size: 0.88rem;">
              Rank #${player.rank} &bull; ${player.seed} &bull; HCP Index: ${player.handicapIndex.toFixed(1)}
            </div>
          </div>
        </div>

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(110px, 1fr)); gap: 10px; margin-bottom: 22px;">
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; text-align: center; border: 1px solid var(--line);">
            <div style="font-size: 0.72rem; color: var(--text-muted);">TOTAL POINTS</div>
            <div style="font-size: 1.3rem; font-weight: 900; color: var(--gold-light);">${player.totalPoints} pts</div>
          </div>
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; text-align: center; border: 1px solid var(--line);">
            <div style="font-size: 0.72rem; color: var(--text-muted);">BIRDIES</div>
            <div style="font-size: 1.3rem; font-weight: 900; color: var(--cyan);">${player.birdies}</div>
          </div>
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; text-align: center; border: 1px solid var(--line);">
            <div style="font-size: 0.72rem; color: var(--text-muted);">GROSS AVG</div>
            <div style="font-size: 1.3rem; font-weight: 900; color: #fff;">${player.grossAvg.toFixed(1)}</div>
          </div>
          <div style="background: var(--bg-card); padding: 12px; border-radius: 10px; text-align: center; border: 1px solid var(--line);">
            <div style="font-size: 0.72rem; color: var(--text-muted);">TEAM CONTRIB</div>
            <div style="font-size: 1.3rem; font-weight: 900; color: #81c784;">${player.contributionPct}%</div>
          </div>
        </div>

        <h3 style="font-size: 1.15rem; color: #fff; margin-bottom: 8px;">2-Man Team Partner History & Contribution</h3>
        <div style="background: var(--bg-card); padding: 14px; border-radius: 10px; border: 1px solid var(--line); margin-bottom: 20px;">
          <ul style="color: var(--text-main); font-size: 0.9rem; padding-left: 18px; line-height: 1.6;">
            ${player.partnerHistory.map(h => `<li>${h}</li>`).join('')}
          </ul>
          <p style="font-size: 0.82rem; color: var(--text-muted); margin-top: 10px;">
            Contributed the counting Best Ball score on <strong>${player.contributionPct}%</strong> of holes played with their partner.
          </p>
        </div>
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
