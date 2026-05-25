// Belote game logic (ported from Python)
const POINTS = {
    'J': [20, 2, 2, 14],
    '9': [14, 0, 0, 9],
    'A': [11, 11, 19, 6],
    '10': [10, 10, 10, 5],
    'K': [4, 4, 4, 3],
    'Q': [3, 3, 3, 1],
    '8': [0, 0, 0, 0],
    '7': [0, 0, 0, 0],
};

const ATOUT_SUITS = {
    'ATOUT_COEUR': 'H',
    'ATOUT_PIQUE': 'S',
    'ATOUT_CARREAU': 'D',
    'ATOUT_TREFLE': 'C',
};

const VALUE_NAMES = {
    'J': 'Valet',
    'Q': 'Dame',
    'K': 'Roi',
    'A': 'As',
};

const SUIT_NAMES = {
    'C': 'Trèfle',
    'D': 'Carreau',
    'H': 'Coeur',
    'S': 'Pique',
};

class BeloteGame {
    constructor() {
        this.mode = null;
        this.isReady = false;
        this.totalPoints = 0;
        this.cardsPlayed = [];
        this.countedCards = new Set();
    }

    setMode(mode) {
        this.mode = mode;
        this.isReady = true;
    }

    getPoints(className) {
        if (className.length < 2) return 0;

        const value = className.slice(0, -1);
        const suit = className.slice(-1);

        if (!(value in POINTS)) return 0;

        const pointsRow = POINTS[value];

        if (this.mode === 'SANS_ATOUT') {
            return pointsRow[2];
        } else if (this.mode === 'TOUT_ATOUT') {
            return pointsRow[3];
        } else if (this.mode in ATOUT_SUITS) {
            const atoutSuit = ATOUT_SUITS[this.mode];
            return suit === atoutSuit ? pointsRow[0] : pointsRow[1];
        }

        return 0;
    }

    addCard(className) {
        if (this.countedCards.has(className)) {
            return 0;
        }

        const points = this.getPoints(className);
        this.totalPoints += points;
        this.cardsPlayed.push(className);
        this.countedCards.add(className);
        return points;
    }

    reset() {
        this.totalPoints = 0;
        this.cardsPlayed = [];
        this.countedCards.clear();
    }
}

function cardNameReadable(className) {
    if (className.length < 2) return className;

    const value = className.slice(0, -1);
    const suit = className.slice(-1);

    const valueStr = VALUE_NAMES[value] || value;
    const suitStr = SUIT_NAMES[suit] || suit;

    return valueStr + ' de ' + suitStr;
}

// Audio feedback using WAV files
let cardAudio = null;
let pointsAudio = null;

function initAudio() {
    if (!cardAudio) {
        cardAudio = new Audio('resources/card.wav');
        pointsAudio = new Audio('resources/points.wav');
        console.log('Audio initialized with WAV files');
    }
}

function playCardSound() {
    if (!cardAudio) {
        console.log("Audio not initialized");
        return;
    }

    try {
        console.log('Playing card sound');
        cardAudio.currentTime = 0;
        cardAudio.play().catch(e => console.error('Play error:', e));
    } catch (e) {
        console.error('Sound error:', e);
    }
}

function playPointsSound() {
    if (!pointsAudio) {
        console.log("Audio not initialized");
        return;
    }

    try {
        console.log('Playing points sound');
        pointsAudio.currentTime = 0;
        pointsAudio.play().catch(e => console.error('Play error:', e));
    } catch (e) {
        console.error('Sound error:', e);
    }
}

// Global state
let game = new BeloteGame();
let detector = null;
let lastCard = null;
let lastCardTime = null;
let validatedCards = new Set();

// UI functions
function testSound() {
    initAudio();
    playCardSound();
    setTimeout(() => playPointsSound(), 500);
}

function setMode(mode) {
    initAudio(); // Initialize audio on user interaction
    game.setMode(mode);
    document.getElementById('mode-selector').style.display = 'none';
    document.getElementById('game-view').style.display = 'block';
    document.getElementById('mode-display').textContent = mode.replace('_', ' ');
    startCamera();
}

function changeMode() {
    stopCamera();
    document.getElementById('game-view').style.display = 'none';
    document.getElementById('mode-selector').style.display = 'flex';
    game.reset();
    validatedCards.clear();
}

function resetGame() {
    game.reset();
    validatedCards.clear();
    updateUI();
}

function updateUI() {
    document.getElementById('points-display').textContent =
        'Points: ' + game.totalPoints + ' | Cartes: ' + game.cardsPlayed.length + '/32';
}

function showLastCard(card, points) {
    const lastCardEl = document.getElementById('last-card');
    lastCardEl.textContent = '✓ ' + cardNameReadable(card) + ' (+' + points + 'pts)';
    lastCardEl.style.display = 'block';

    setTimeout(function () {
        lastCardEl.style.display = 'none';
    }, 2000);
}

// Camera handling
let stream = null;
let animationId = null;

async function startCamera() {
    try {
        stream = await navigator.mediaDevices.getUserMedia({
            video: { facingMode: 'environment', width: 640, height: 480 }
        });
        const video = document.getElementById('camera');
        video.srcObject = stream;

        // Initialize detector
        detector = new CardDetector();
        await detector.init();

        // Start detection loop
        detectLoop();
    } catch (err) {
        alert('Erreur caméra: ' + err.message);
    }
}

function stopCamera() {
    if (stream) {
        stream.getTracks().forEach(track => track.stop());
        stream = null;
    }
    if (animationId) {
        cancelAnimationFrame(animationId);
        animationId = null;
    }
}

async function detectLoop() {
    if (!game.isReady) return;

    const video = document.getElementById('camera');
    const canvas = document.getElementById('overlay');
    const ctx = canvas.getContext('2d');

    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;

    // Run detection
    const detections = await detector.detect(video);

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw detections
    detections.forEach(det => {
        const [x1, y1, x2, y2] = det.bbox;
        ctx.strokeStyle = '#00ff00';
        ctx.lineWidth = 2;
        ctx.strokeRect(x1, y1, x2 - x1, y2 - y1);
    });

    // Check for stable card
    if (detections.length > 0) {
        const bestCard = detections[0].className;
        const isNew = !validatedCards.has(bestCard);

        console.log('Detection:', bestCard, 'isNew:', isNew);

        if (isNew) {
            validatedCards.add(bestCard);
            const points = game.addCard(bestCard);

            console.log('Card added, points:', points);

            if (points > 0) {
                console.log('Playing card sound because points > 0');
                showLastCard(bestCard, points);
                playPointsSound();
            } else {
                console.log('Playing points sound');
                playCardSound();
            }

            updateUI();
        }
    }

    animationId = requestAnimationFrame(detectLoop);
}

// Service worker registration
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js');
}
