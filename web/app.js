/* ============================================================
   IronHide — Frontend Application Logic
   Communicates with the SWI-Prolog HTTP backend (port 8080)
   Falls back to client-side JS inference if backend is offline
   ============================================================ */

'use strict';

// ── Constants ────────────────────────────────────────────────
const API_BASE = 'http://localhost:8080';

// All 28 rules (used for the rules table + fallback inference)
const ALL_RULES = [
  { id:'R1',  cat:'bmi',              text:'BMI < 17.0 → Moderate and severe thinness',
    expl:'WHO: BMI below 17 indicates significant nutritional deficiency requiring medical attention.' },
  { id:'R2',  cat:'bmi',              text:'BMI < 18.5 → Underweight',
    expl:'WHO: BMI below 18.5 indicates underweight status; increased caloric intake recommended.' },
  { id:'R3',  cat:'bmi',              text:'BMI 18.5–24.9 → Normal weight',
    expl:'WHO: Healthy weight range; maintain through balanced diet and regular activity.' },
  { id:'R4',  cat:'bmi',              text:'BMI 25.0–29.9 → Overweight',
    expl:'WHO: BMI above 25 increases risk of cardiovascular disease and diabetes.' },
  { id:'R5',  cat:'bmi',              text:'BMI ≥ 30.0 → Obese',
    expl:'WHO: Obesity significantly increases chronic disease risk; weight management is critical.' },
  { id:'R6',  cat:'physical_activity',text:'Age 5–17: Do at least 60 min/day of moderate-to-vigorous intensity physical activity',
    expl:'WHO Guidelines on Physical Activity & Sedentary Behaviour 2020, p.18: Children need daily active play, sports, or structured exercise.' },
  { id:'R7',  cat:'physical_activity',text:'Age 5–17: Include muscle- and bone-strengthening activities at least 3 times per week',
    expl:'WHO 2020, p.19: Bone-strengthening activities during growth years build skeletal density.' },
  { id:'R8',  cat:'physical_activity',text:'Age 18–64: Do at least 150 min moderate-intensity, or at least 75 min vigorous-intensity, or equivalent combination per week',
    expl:'WHO 2020, p.26: This level significantly reduces chronic disease risk for adults.' },
  { id:'R9',  cat:'physical_activity',text:'Age 18–64 (extra benefits): Increase moderate-intensity activity to 300 min per week',
    expl:'WHO 2020, p.27: Additional benefits include reduced depression and cancer risk.' },
  { id:'R10', cat:'physical_activity',text:'Age 65+: Do at least 150 min moderate-intensity or 75 min vigorous-intensity per week',
    expl:'WHO 2020, p.34: Same base activity threshold applies to older adults for chronic disease prevention.' },
  { id:'R11', cat:'physical_activity',text:'Age 65+: Can increase to 300 min/week for additional health benefits',
    expl:'WHO 2020, p.35: Higher activity provides greater benefits in older adults.' },
  { id:'R12', cat:'physical_activity',text:'Age 65+: Do activity that enhances balance and prevents falls, 3 or more days per week',
    expl:'WHO 2020, p.35: Fall prevention through balance training reduces injury risk significantly.' },
  { id:'R13', cat:'physical_activity',text:'Age 65+: Do muscle-strengthening involving major muscle groups on 2 or more days per week',
    expl:'WHO 2020, p.35: Muscle-strengthening counteracts age-related muscle loss (sarcopenia).' },
  { id:'R14', cat:'physical_activity',text:'Hypertension: Aim for at least 150 min/week of moderate-intensity aerobic activity',
    expl:'AHA Guidelines (heart.org): Aerobic activity lowers blood pressure by improving vascular flexibility.' },
  { id:'R15', cat:'physical_activity',text:'Hypertension: Use a combination of aerobic exercise and/or resistance training',
    expl:'AHA: Combining aerobic and resistance training provides complementary BP management.' },
  { id:'R16', cat:'physical_activity',text:'Hypertension: Warm up for several minutes before exercise and cool down afterwards',
    expl:'AHA: Warm-up/cool-down prevents hypertensive spikes during sudden exercise transitions.' },
  { id:'R17', cat:'physical_activity',text:'Diabetes: Do at least 150 min/week moderate-to-vigorous activity, spread over 3 days, no more than 2 consecutive days without activity',
    expl:'ADA Standards of Medical Care 2023: Spreading activity prevents consecutive inactivity that impairs insulin sensitivity.' },
  { id:'R18', cat:'physical_activity',text:'Diabetes: Do resistance exercise 2 to 3 sessions/week on non-consecutive days',
    expl:'ADA 2023: Resistance training 2-3×/week improves glucose uptake and insulin sensitivity in muscles.' },
  { id:'R19', cat:'physical_activity',text:'Diabetes + Age 65+: Add flexibility and balance training 2 to 3 times per week',
    expl:'ADA 2023: Older adults with diabetes benefit from balance training to offset increased fall risk from neuropathy.' },
  { id:'R20', cat:'physical_activity',text:'Type 2 Diabetes: Break up long sitting with a 15 min walk after meals, or 3 min light walking or body-weight exercise every 30 min',
    expl:'ADA 2023: Post-meal walking reduces glucose spikes by utilizing glucose for muscle activity.' },
  { id:'R21', cat:'diet',             text:'Choose whole grains, including parboiled or less polished rice, over refined grains',
    expl:'SLNS Dietary Guidelines for Sri Lankans: Whole grains have lower glycaemic index, aiding weight and blood sugar management.' },
  { id:'R22', cat:'diet',             text:'Eat at least two vegetables (one green leafy) and two fruits daily',
    expl:'SLNS: Two vegetables and two fruits daily provide essential micronutrients, fibre, and antioxidants.' },
  { id:'R23', cat:'diet',             text:'Eat fish, egg, or lean meat with pulses in every meal',
    expl:'SLNS: Protein from fish/egg/lean meat with pulses ensures complete amino acid profiles.' },
  { id:'R24', cat:'diet',             text:'Limit salty foods and adding salt to food',
    expl:'SLNS: Excess salt (sodium) raises blood pressure; recommended intake is <5g NaCl/day.' },
  { id:'R25', cat:'diet',             text:'Limit sugary drinks, biscuits, cakes, sweets, and sweeteners',
    expl:'SLNS: Sugary foods cause blood glucose spikes, weight gain, and dental problems.' },
  { id:'R26', cat:'diet',             text:'Drink 8 to 10 glasses (1.5 to 2.0 L) of water through the day',
    expl:'SLNS: Adequate hydration maintains metabolism, kidney function, and physical performance.' },
  { id:'R27', cat:'physical_activity',text:'Do 150 to 300 min/week of moderate physical activity',
    expl:'SLNS: Regular moderate physical activity reduces obesity, cardiovascular disease, and diabetes risk.' },
  { id:'R28', cat:'lifestyle',        text:'Sleep 7 to 8 hours continuously each day',
    expl:'SLNS: 7-8 hours of sleep regulates hunger hormones (ghrelin/leptin) and supports muscle recovery.' },
];

// ── Client-side Inference (Fallback) ─────────────────────────
// Mirrors the Prolog rules in JavaScript for offline demo

function computeBMI(weight, height) {
  const hm = height / 100;
  return Math.round((weight / (hm * hm)) * 10) / 10;
}

function classifyBMI(bmi) {
  if (bmi < 17.0) return 'moderate_thinness';
  if (bmi < 18.5) return 'underweight';
  if (bmi <= 24.9) return 'normal';
  if (bmi < 30.0) return 'overweight';
  return 'obese';
}

function classifyAgeGroup(age) {
  if (age >= 5  && age <= 17) return 'child';
  if (age >= 18 && age <= 64) return 'adult';
  if (age >= 65)               return 'older_adult';
  return 'unknown';
}

const BMI_LABELS = {
  moderate_thinness: 'Moderate & Severe Thinness (BMI < 17.0)',
  underweight:       'Underweight (BMI < 18.5)',
  normal:            'Normal Weight (BMI 18.5–24.9)',
  overweight:        'Overweight (BMI 25.0–29.9)',
  obese:             'Obese (BMI ≥ 30.0)',
};
const AGE_LABELS = {
  child:       'Child (5–17 years)',
  adult:       'Adult (18–64 years)',
  older_adult: 'Older Adult (65+ years)',
  unknown:     'Unknown Age Group',
};

function applyBackwardChaining(ageGroup, conditions, wantsExtra) {
  const recs = [];

  // R6-R7: Children
  if (ageGroup === 'child') {
    recs.push({ rule_id:'R6', category:'physical_activity', ...getRuleInfo('R6') });
    recs.push({ rule_id:'R7', category:'physical_activity', ...getRuleInfo('R7') });
  }

  // R8-R9: Adults 18-64
  if (ageGroup === 'adult') {
    recs.push({ rule_id:'R8', category:'physical_activity', ...getRuleInfo('R8') });
    if (wantsExtra)
      recs.push({ rule_id:'R9', category:'physical_activity', ...getRuleInfo('R9') });
  }

  // R10-R13: Older adults 65+
  if (ageGroup === 'older_adult') {
    recs.push({ rule_id:'R10', category:'physical_activity', ...getRuleInfo('R10') });
    recs.push({ rule_id:'R11', category:'physical_activity', ...getRuleInfo('R11') });
    recs.push({ rule_id:'R12', category:'physical_activity', ...getRuleInfo('R12') });
    recs.push({ rule_id:'R13', category:'physical_activity', ...getRuleInfo('R13') });
  }

  // R14-R16: Hypertension
  if (conditions.includes('hypertension')) {
    recs.push({ rule_id:'R14', category:'physical_activity', ...getRuleInfo('R14') });
    recs.push({ rule_id:'R15', category:'physical_activity', ...getRuleInfo('R15') });
    recs.push({ rule_id:'R16', category:'physical_activity', ...getRuleInfo('R16') });
  }

  // R17-R19: Diabetes
  if (conditions.includes('diabetes')) {
    recs.push({ rule_id:'R17', category:'physical_activity', ...getRuleInfo('R17') });
    recs.push({ rule_id:'R18', category:'physical_activity', ...getRuleInfo('R18') });
    if (ageGroup === 'older_adult')
      recs.push({ rule_id:'R19', category:'physical_activity', ...getRuleInfo('R19') });
  }

  // R20: Type 2 Diabetes
  if (conditions.includes('type2_diabetes')) {
    recs.push({ rule_id:'R20', category:'physical_activity', ...getRuleInfo('R20') });
  }

  // R21-R27: Diet (adults and older adults)
  if (ageGroup === 'adult' || ageGroup === 'older_adult') {
    ['R21','R22','R23','R24','R25','R26'].forEach(id => {
      recs.push({ rule_id: id, category: 'diet', ...getRuleInfo(id) });
    });
    recs.push({ rule_id:'R27', category:'physical_activity', ...getRuleInfo('R27') });
    recs.push({ rule_id:'R28', category:'lifestyle',        ...getRuleInfo('R28') });
  }

  return recs;
}

function getRuleInfo(id) {
  const r = ALL_RULES.find(r => r.id === id);
  return r ? { recommendation: r.text, explanation: r.expl } : { recommendation:'', explanation:'' };
}

// ── UI Rendering ──────────────────────────────────────────────

function renderResults(data) {
  const container = document.getElementById('resultsContainer');
  const placeholder = document.getElementById('placeholderState');
  placeholder.style.display = 'none';
  container.style.display = 'block';

  // BMI display
  document.getElementById('bmiValue').textContent = data.bmi;
  const catEl = document.getElementById('bmiCategory');
  catEl.textContent = data.bmi_category;
  catEl.style.background = bmiColor(data.bmi_category, '0.15');
  catEl.style.color = bmiColor(data.bmi_category, '1');
  catEl.style.borderColor = bmiColor(data.bmi_category, '0.4');
  document.getElementById('ageGroupDisplay').textContent = data.age_group;

  // BMI bar position
  const pos = bmiBarPosition(data.bmi);
  document.getElementById('bmiBar').style.setProperty('--bmi-pos', pos + '%');

  // Reasoning chain
  const chainSteps = document.getElementById('chainSteps');
  chainSteps.innerHTML = '';
  data.reasoning_chain.forEach((step, i) => {
    chainSteps.innerHTML += `
      <div class="chain-step">
        <span class="step-num">${i+1}</span>
        <span>${step}</span>
      </div>`;
  });

  // Recommendations
  const categories = [
    { key:'physical_activity', blockId:'physicalBlock', listId:'physicalList' },
    { key:'diet',              blockId:'dietBlock',     listId:'dietList' },
    { key:'lifestyle',         blockId:'lifestyleBlock',listId:'lifestyleList' },
  ];

  categories.forEach(({ key, blockId, listId }) => {
    const items = data.recommendations.filter(r => r.category === key);
    const block = document.getElementById(blockId);
    const list  = document.getElementById(listId);
    if (items.length > 0) {
      block.style.display = 'block';
      list.innerHTML = items.map(r => `
        <div class="rec-item">
          <div class="rec-header">
            <span class="rec-rule-badge">${r.rule_id}</span>
            <span class="rec-text">${r.recommendation}</span>
          </div>
          <div class="rec-explanation">↳ ${r.explanation}</div>
        </div>
      `).join('');
    } else {
      block.style.display = 'none';
    }
  });
}

function bmiBarPosition(bmi) {
  // Map BMI 10–40 to 0–100%
  const min = 10, max = 40;
  return Math.min(100, Math.max(0, ((bmi - min) / (max - min)) * 100));
}

function bmiColor(label, alpha) {
  if (label.includes('Thinness'))       return `rgba(96,165,250,${alpha})`;
  if (label.includes('Underweight'))    return `rgba(52,211,153,${alpha})`;
  if (label.includes('Normal'))         return `rgba(16,185,129,${alpha})`;
  if (label.includes('Overweight'))     return `rgba(245,158,11,${alpha})`;
  if (label.includes('Obese'))          return `rgba(239,68,68,${alpha})`;
  return `rgba(99,102,241,${alpha})`;
}

// ── Rules Table ───────────────────────────────────────────────

function renderRules(filterCat = 'all') {
  const grid = document.getElementById('rulesGrid');
  const rules = filterCat === 'all' ? ALL_RULES : ALL_RULES.filter(r => r.cat === filterCat);
  grid.innerHTML = rules.map(r => `
    <div class="rule-card" data-cat="${r.cat}">
      <div class="rule-card-header">
        <span class="rule-id">${r.id}</span>
        <span class="rule-cat-badge cat-${r.cat}">${r.cat.replace('_',' ')}</span>
      </div>
      <p class="rule-text">${r.text}</p>
      <p class="rule-expl">${r.expl}</p>
    </div>
  `).join('');
}

// ── Loading Animation ─────────────────────────────────────────

const LOADING_STEPS = [
  'Asserting user facts...',
  'Running forward chaining: classifying BMI...',
  'Running forward chaining: classifying age group...',
  'Deriving health conditions...',
  'Running backward chaining: querying rules...',
  'Generating explanations...',
];

async function showLoading() {
  const overlay = document.getElementById('loadingOverlay');
  const stepEl  = document.getElementById('loadingSteps');
  overlay.style.display = 'flex';
  for (let i = 0; i < LOADING_STEPS.length; i++) {
    stepEl.textContent = LOADING_STEPS[i];
    await sleep(300);
  }
}
function hideLoading() {
  document.getElementById('loadingOverlay').style.display = 'none';
}
const sleep = ms => new Promise(r => setTimeout(r, ms));

// ── Form Submit ───────────────────────────────────────────────

document.getElementById('analyzerForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const btn = document.getElementById('analyzeBtn');
  btn.disabled = true;

  await showLoading();

  const age        = parseFloat(document.getElementById('age').value);
  const weight     = parseFloat(document.getElementById('weight').value);
  const height     = parseFloat(document.getElementById('height').value);
  const goal       = document.getElementById('goal').value;
  const conditions = Array.from(document.querySelectorAll('input[name="conditions"]:checked'))
                          .map(c => c.value);
  const wantsExtra = document.getElementById('wantsExtra').checked;

  let data;
  try {
    // Try Prolog backend first
    const resp = await fetch(`${API_BASE}/analyze`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ age, weight, height, goal, conditions, wants_extra_benefits: wantsExtra }),
    });
    if (!resp.ok) throw new Error('Backend error');
    data = await resp.json();
  } catch (err) {
    // ── Fallback: client-side JS inference ──────────────────
    console.warn('Prolog backend offline — using JS inference fallback');
    const bmi      = computeBMI(weight, height);
    const bmiCat   = classifyBMI(bmi);
    const ageGroup = classifyAgeGroup(age);
    const recs     = applyBackwardChaining(ageGroup, conditions, wantsExtra);

    data = {
      bmi,
      bmi_category: BMI_LABELS[bmiCat] || bmiCat,
      age_group:    AGE_LABELS[ageGroup] || ageGroup,
      recommendations: recs,
      reasoning_chain: [
        `Step 1: Computed BMI = ${bmi} from weight=${weight}kg, height=${height}cm`,
        `Step 2: Applied R1–R5 → BMI Category = "${BMI_LABELS[bmiCat]}"`,
        `Step 3: Applied age rules → Age Group = "${AGE_LABELS[ageGroup]}"`,
        `Step 4: Registered conditions: [${conditions.join(', ') || 'none'}]`,
        `Step 5: Backward chaining queried ${recs.length} applicable rules`,
        `Step 6: Generated recommendations with source explanations`,
        `(Note: Using JS inference — Prolog backend not detected on localhost:8080)`,
      ],
    };
  }

  hideLoading();
  btn.disabled = false;
  renderResults(data);

  // Scroll to results
  document.getElementById('outputPanel').scrollIntoView({ behavior: 'smooth', block: 'start' });
});

// ── Filter Buttons ────────────────────────────────────────────

document.querySelectorAll('.filter-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    renderRules(btn.dataset.filter);
  });
});

// ── Navigation Highlight ──────────────────────────────────────

const sections = document.querySelectorAll('section[id]');
const pills    = document.querySelectorAll('.pill');

const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      pills.forEach(p => p.classList.remove('active'));
      const active = document.querySelector(`.pill[href="#${entry.target.id}"]`);
      if (active) active.classList.add('active');
    }
  });
}, { threshold: 0.5 });

sections.forEach(s => observer.observe(s));

// ── Initialize ────────────────────────────────────────────────

renderRules();
