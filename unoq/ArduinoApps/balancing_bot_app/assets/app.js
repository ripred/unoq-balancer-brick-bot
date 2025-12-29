let socket;
let pollTimer = null;
let lastTelemetry = null;
let kickOverlayMagnitude = 0;
let kickOverlayStart = 0;
let kickOverlayDuration = 0;
let kickOverlaySign = 1;
const statusEl = document.getElementById('status');
const errorEl = document.getElementById('error-container');
const themeToggle = document.getElementById('theme-toggle');

const angleEl = document.getElementById('angle');
const gyroEl = document.getElementById('gyro');
const accelEl = document.getElementById('accel');
const motorEl = document.getElementById('motor');
const encEl = document.getElementById('enc');
const modeEl = document.getElementById('mode');
const imuEl = document.getElementById('imu');

const pidP = document.getElementById('pid-p');
const pidI = document.getElementById('pid-i');
const pidD = document.getElementById('pid-d');
const pidApply = document.getElementById('pid-apply');
const pidHz = document.getElementById('pid-hz');
const pidHzApply = document.getElementById('pid-hz-apply');

const setpointEl = document.getElementById('setpoint');
const setpointApply = document.getElementById('setpoint-apply');

const imuModel = document.getElementById('imu-model');
const imuApply = document.getElementById('imu-apply');

const axisMode = document.getElementById('axis-mode');
const axisApply = document.getElementById('axis-apply');

const axisSign = document.getElementById('axis-sign');
const axisSignApply = document.getElementById('axis-sign-apply');

const motorLeft = document.getElementById('motor-left');
const motorRight = document.getElementById('motor-right');
const motorApply = document.getElementById('motor-apply');

const encLeft = document.getElementById('enc-left');
const encRight = document.getElementById('enc-right');
const encApply = document.getElementById('enc-apply');

const runMode = document.getElementById('run-mode');
const modeApply = document.getElementById('mode-apply');

const kickAngle = document.getElementById('kick-angle');
const kickApply = document.getElementById('kick-apply');

const motorTestSpeed = document.getElementById('motor-test-speed');
const motorTestLeftFwd = document.getElementById('motor-test-left-fwd');
const motorTestLeftRev = document.getElementById('motor-test-left-rev');
const motorTestRightFwd = document.getElementById('motor-test-right-fwd');
const motorTestRightRev = document.getElementById('motor-test-right-rev');
const motorTestStop = document.getElementById('motor-test-stop');

const chart = document.getElementById('chart');
const chartCtx = chart.getContext('2d');
const wire = document.getElementById('wireframe');
const wireCtx = wire.getContext('2d');

const angleHistory = [];
const MAX_POINTS = 200;

const UI_ANGLE_SCALE = 6.0;
let chartScale = UI_ANGLE_SCALE;

function applyTheme(theme) {
    document.body.dataset.theme = theme;
    localStorage.setItem('bb_theme', theme);
}

function initTheme() {
    const saved = localStorage.getItem('bb_theme');
    if (saved === 'light' || saved === 'dark') {
        applyTheme(saved);
    } else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
        applyTheme('dark');
    } else {
        applyTheme('light');
    }
}

function applyLayoutClass() {
    const w = window.innerWidth || document.documentElement.clientWidth;
    const h = window.innerHeight || document.documentElement.clientHeight;
    const mobileHint = /Mobi|Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
    const isPortrait = h > (w * 1.15);
    const isNarrow = w < 900;
    const isMobileLayout = (mobileHint && w < 1100) || isNarrow || (isPortrait && w < 1000);
    document.body.dataset.layout = isMobileLayout ? 'mobile' : 'desktop';
    if (!isMobileLayout) {
        const controls = Math.max(360, Math.min(520, Math.round(w * 0.32)));
        const contentMin = Math.max(460, Math.min(1000, Math.round(w * 0.58)));
        document.body.style.setProperty('--controls-col', `${controls}px`);
        document.body.style.setProperty('--content-min', `${contentMin}px`);
    }
}

function resizeCanvases() {
    const w = window.innerWidth || document.documentElement.clientWidth;
    const h = window.innerHeight || document.documentElement.clientHeight;
    const headerOffset = 180;
    const available = Math.max(420, h - headerOffset);
    const historyH = Math.max(200, Math.min(320, Math.round(available * 0.28)));
    const wireH = Math.max(260, Math.min(520, Math.round(available * 0.48)));
    document.body.style.setProperty('--history-h', `${historyH}px`);
    document.body.style.setProperty('--wire-h', `${wireH}px`);

    const chartRect = chart.getBoundingClientRect();
    if (chartRect.width > 0 && chartRect.height > 0) {
        chart.width = Math.round(chartRect.width);
        chart.height = Math.round(chartRect.height);
    }
    const wireRect = wire.getBoundingClientRect();
    if (wireRect.width > 0 && wireRect.height > 0) {
        wire.width = Math.round(wireRect.width);
        wire.height = Math.round(wireRect.height);
    }
    drawChart();
    if (lastTelemetry) {
        drawWireframe(lastTelemetry.angle_deg);
    }
}

function setStatus(text, isError = false) {
    statusEl.textContent = text;
    if (isError) {
        errorEl.textContent = text;
        errorEl.style.display = 'block';
    } else {
        errorEl.style.display = 'none';
    }
}

function drawChart() {
    const maxAbs = angleHistory.reduce((acc, v) => Math.max(acc, Math.abs(v)), 0);
    if (maxAbs > 0) {
        const maxScale = (chart.height * 0.45) / maxAbs;
        chartScale = Math.min(UI_ANGLE_SCALE, maxScale);
    } else {
        chartScale = UI_ANGLE_SCALE;
    }
    chartCtx.clearRect(0, 0, chart.width, chart.height);

    const styles = getComputedStyle(document.body);
    const gridColor = styles.getPropertyValue('--border').trim() || '#e6e6e6';
    const labelColor = styles.getPropertyValue('--muted').trim() || '#6a6a6a';
    const labelFont = '12px "Avenir", "Gill Sans", "Trebuchet MS", sans-serif';
    const padLeft = 46;
    const padRight = 6;
    const usableWidth = chart.width - padLeft - padRight;

    const maxVisibleDeg = (chart.height * 0.45) / chartScale;
    const maxTicks = Math.min(6, Math.max(4, Math.floor(chart.height / 40)));

    function niceStep(raw) {
        if (raw <= 0) return 1;
        const exp = Math.floor(Math.log10(raw));
        const base = raw / Math.pow(10, exp);
        let nice = 1;
        if (base >= 5) nice = 5;
        else if (base >= 2) nice = 2;
        return nice * Math.pow(10, exp);
    }

    const step = niceStep(maxVisibleDeg / maxTicks);
    const maxTick = Math.ceil(maxVisibleDeg / step) * step;
    const ticks = [];
    for (let t = -maxTick; t <= maxTick + (step * 0.5); t += step) {
        ticks.push(t);
    }
    chartCtx.strokeStyle = gridColor;
    chartCtx.lineWidth = 1;
    chartCtx.font = labelFont;
    chartCtx.fillStyle = labelColor;

    let lastLabelY = null;
    ticks.forEach((t) => {
        const y = chart.height / 2 - (t * chartScale);
        if (y < 0 || y > chart.height) return;
        chartCtx.beginPath();
        chartCtx.moveTo(padLeft, y);
        chartCtx.lineTo(chart.width - padRight, y);
        chartCtx.stroke();
        if (lastLabelY === null || Math.abs(y - lastLabelY) > 14) {
            chartCtx.fillText(`${t.toFixed(1)}°`, 6, y + 4);
            lastLabelY = y;
        }
    });

    chartCtx.strokeStyle = '#1fd1c7';
    chartCtx.lineWidth = 2;
    chartCtx.beginPath();
    angleHistory.forEach((v, i) => {
        const x = padLeft + (i / (MAX_POINTS - 1)) * usableWidth;
        const y = chart.height / 2 - (v * chartScale);
        if (i === 0) chartCtx.moveTo(x, y);
        else chartCtx.lineTo(x, y);
    });
    chartCtx.stroke();
}

function drawWireframe(angle) {
    wireCtx.clearRect(0, 0, wire.width, wire.height);

    const overlay = getKickOverlay();
    const useAngle = (overlay !== null) ? angle + overlay : angle;
    const scaled = useAngle * (UI_ANGLE_SCALE / 2);
    const rad = scaled * Math.PI / 180;

    const cx = wire.width * 0.45;
    const groundY = wire.height - 14;

    const bodyW = 50;
    const bodyH = 180;
    const stemH = 40;
    const wheelR = 28;

    const pivotX = cx;
    const pivotY = groundY - wheelR;
    const bodyCenterX = pivotX;
    const bodyCenterY = pivotY - wheelR - stemH - bodyH / 2 + 10;

    function rot(x, y) {
        const dx = x - pivotX;
        const dy = y - pivotY;
        const rx = dx * Math.cos(rad) - dy * Math.sin(rad);
        const ry = dx * Math.sin(rad) + dy * Math.cos(rad);
        return [pivotX + rx, pivotY + ry];
    }

    const halfW = bodyW / 2;
    const halfH = bodyH / 2;
    const corners = [
        rot(bodyCenterX - halfW, bodyCenterY - halfH),
        rot(bodyCenterX + halfW, bodyCenterY - halfH),
        rot(bodyCenterX + halfW, bodyCenterY + halfH),
        rot(bodyCenterX - halfW, bodyCenterY + halfH),
    ];

    wireCtx.strokeStyle = '#1fd1c7';
    wireCtx.lineWidth = 2;

    wireCtx.beginPath();
    wireCtx.moveTo(corners[0][0], corners[0][1]);
    wireCtx.lineTo(corners[1][0], corners[1][1]);
    wireCtx.lineTo(corners[2][0], corners[2][1]);
    wireCtx.lineTo(corners[3][0], corners[3][1]);
    wireCtx.closePath();
    wireCtx.stroke();

    const stemTop = rot(pivotX, pivotY - wheelR - stemH + 10);
    wireCtx.beginPath();
    wireCtx.moveTo(stemTop[0], stemTop[1]);
    wireCtx.lineTo(pivotX, pivotY);
    wireCtx.stroke();

    wireCtx.beginPath();
    wireCtx.arc(pivotX, pivotY, wheelR, 0, Math.PI * 2);
    wireCtx.stroke();

    wireCtx.beginPath();
    wireCtx.moveTo(pivotX - 140, groundY);
    wireCtx.lineTo(pivotX + 140, groundY);
    wireCtx.stroke();
}

function getKickOverlay() {
    if (!kickOverlayDuration) {
        return null;
    }
    const elapsed = Date.now() - kickOverlayStart;
    if (elapsed < 0 || elapsed > kickOverlayDuration) {
        kickOverlayDuration = 0;
        return null;
    }
    const t = elapsed / kickOverlayDuration;
    const decay = Math.exp(-3.2 * t);
    const wobble = Math.sin(t * 10.0 + 0.8);
    return kickOverlaySign * kickOverlayMagnitude * decay * wobble;
}

function applyConfig(cfg) {
    pidP.value = cfg.pid.p;
    pidI.value = cfg.pid.i;
    pidD.value = cfg.pid.d;
    pidHz.value = cfg.pid_hz || 50;
    setpointEl.value = cfg.setpoint;
    imuModel.value = cfg.imu_model;
    axisMode.value = cfg.axis_mode || 'pitch';
    axisSign.value = String(cfg.axis_sign || 1);
    motorLeft.value = String((cfg.motor_invert && cfg.motor_invert.left) || 1);
    motorRight.value = String((cfg.motor_invert && cfg.motor_invert.right) || 1);
    encLeft.value = String((cfg.encoder_invert && cfg.encoder_invert.left) || 1);
    encRight.value = String((cfg.encoder_invert && cfg.encoder_invert.right) || 1);
    runMode.value = cfg.mode === 'real' ? 'real' : 'sim';
    modeEl.textContent = cfg.mode;
    imuEl.textContent = cfg.imu_model;
}

function updateTelemetry(t) {
    lastTelemetry = t;
    angleEl.textContent = t.angle_deg.toFixed(2);
    gyroEl.textContent = t.gyro_dps.toFixed(2);
    accelEl.textContent = t.accel_g.toFixed(2);
    motorEl.textContent = `${t.motor_pwm.left}/${t.motor_pwm.right}`;
    encEl.textContent = `${t.encoders.left}/${t.encoders.right}`;
    modeEl.textContent = t.mode;
    imuEl.textContent = t.imu_model;

    angleHistory.push(t.angle_deg);
    if (angleHistory.length > MAX_POINTS) angleHistory.shift();
    drawChart();
    drawWireframe(t.angle_deg);
}

async function fetchStatusOnce() {
    const res = await fetch('/status');
    const data = await res.json();
    if (data && data.config) {
        applyConfig(data.config);
    }
    if (data && data.telemetry) {
        updateTelemetry(data.telemetry);
    }
}

async function sendHttp(path, params) {
    const url = new URL(path, window.location.origin);
    Object.entries(params).forEach(([k, v]) => {
        if (v !== null && v !== undefined && v !== '' && !Number.isNaN(v)) {
            url.searchParams.set(k, v);
        }
    });
    await fetch(url.toString());
}

function startPolling() {
    if (pollTimer) return;
    setStatus('Connected (polling)');
    pollTimer = setInterval(async () => {
        try {
            await fetchStatusOnce();
        } catch (err) {
            setStatus(`Polling error: ${err.message}`, true);
        }
    }, 250);
}

function stopPolling() {
    if (pollTimer) {
        clearInterval(pollTimer);
        pollTimer = null;
    }
}

function initSocket() {
    if (typeof io === 'undefined') {
        setStatus('socket.io not loaded, using polling', true);
        startPolling();
        return;
    }

    socket = io(`http://${window.location.host}`);

    socket.on('connect', () => {
        stopPolling();
        setStatus('Connected');
        socket.emit('get_initial_state', {});
    });

    socket.on('disconnect', () => {
        setStatus('Disconnected, polling', true);
        startPolling();
    });

    socket.on('connect_error', (err) => {
        setStatus(`Connect error: ${err.message}, polling`, true);
        startPolling();
    });

    socket.on('config', (cfg) => {
        applyConfig(cfg);
    });

    socket.on('telemetry', (t) => {
        updateTelemetry(t);
    });
}

if (themeToggle) {
    themeToggle.addEventListener('click', () => {
        const next = document.body.dataset.theme === 'dark' ? 'light' : 'dark';
        applyTheme(next);
    });
}

initTheme();
applyLayoutClass();
resizeCanvases();
window.addEventListener('resize', () => {
    applyLayoutClass();
    resizeCanvases();
});

pidApply.addEventListener('click', async () => {
    const payload = {
        p: parseFloat(pidP.value),
        i: parseFloat(pidI.value),
        d: parseFloat(pidD.value)
    };
    if (socket) {
        socket.emit('set_pid', payload);
    } else {
        await sendHttp('/set_pid', payload);
    }
});

pidHzApply.addEventListener('click', async () => {
    const payload = { pid_hz: parseInt(pidHz.value, 10) };
    if (socket) {
        socket.emit('set_pid_hz', payload);
    } else {
        await sendHttp('/set_pid_hz', payload);
    }
});

setpointApply.addEventListener('click', async () => {
    const payload = { setpoint: parseFloat(setpointEl.value) };
    if (socket) {
        socket.emit('set_setpoint', payload);
    } else {
        await sendHttp('/set_setpoint', payload);
    }
});

imuApply.addEventListener('click', async () => {
    const payload = { imu_model: imuModel.value };
    if (socket) {
        socket.emit('set_imu_model', payload);
    } else {
        await sendHttp('/set_imu_model', payload);
    }
});

axisApply.addEventListener('click', async () => {
    const payload = { axis_mode: axisMode.value };
    if (socket) {
        socket.emit('set_axis_mode', payload);
    } else {
        await sendHttp('/set_axis_mode', payload);
    }
});

axisSignApply.addEventListener('click', async () => {
    const payload = { axis_sign: parseInt(axisSign.value, 10) };
    if (socket) {
        socket.emit('set_axis_sign', payload);
    } else {
        await sendHttp('/set_axis_sign', payload);
    }
});

motorApply.addEventListener('click', async () => {
    const payload = {
        left: parseInt(motorLeft.value, 10),
        right: parseInt(motorRight.value, 10)
    };
    if (socket) {
        socket.emit('set_motor_invert', payload);
    } else {
        await sendHttp('/set_motor_invert', payload);
    }
});

encApply.addEventListener('click', async () => {
    const payload = {
        left: parseInt(encLeft.value, 10),
        right: parseInt(encRight.value, 10)
    };
    if (socket) {
        socket.emit('set_encoder_invert', payload);
    } else {
        await sendHttp('/set_encoder_invert', payload);
    }
});

modeApply.addEventListener('click', async () => {
    const payload = { mode: runMode.value };
    if (socket) {
        socket.emit('set_mode', payload);
    } else {
        await sendHttp('/set_mode', payload);
    }
});

kickApply.addEventListener('click', async () => {
    const payload = { angle: parseFloat(kickAngle.value) };
    console.log("[balancing_bot] face-plant click", payload);
    const angle = Number.isFinite(payload.angle) ? payload.angle : 0;
    kickOverlayMagnitude = Math.min(80, Math.max(10, Math.abs(angle)));
    kickOverlaySign = angle >= 0 ? 1 : -1;
    kickOverlayStart = Date.now();
    kickOverlayDuration = 2200;
    if (lastTelemetry) {
        updateTelemetry({
            ...lastTelemetry,
            angle_deg: angle,
            gyro_dps: angle >= 0 ? 12 : -12
        });
    }
    if (socket) {
        socket.emit('kick', payload);
    } else {
        await sendHttp('/kick', payload);
    }
});

async function sendMotorTest(left, right) {
    const payload = {
        left: left,
        right: right,
        duration_ms: 1200
    };
    if (socket) {
        socket.emit('motor_test', payload);
    } else {
        await sendHttp('/motor_test', payload);
    }
}

motorTestLeftFwd.addEventListener('click', async () => {
    const speed = parseInt(motorTestSpeed.value, 10);
    await sendMotorTest(speed, 0);
});

motorTestLeftRev.addEventListener('click', async () => {
    const speed = parseInt(motorTestSpeed.value, 10);
    await sendMotorTest(-speed, 0);
});

motorTestRightFwd.addEventListener('click', async () => {
    const speed = parseInt(motorTestSpeed.value, 10);
    await sendMotorTest(0, speed);
});

motorTestRightRev.addEventListener('click', async () => {
    const speed = parseInt(motorTestSpeed.value, 10);
    await sendMotorTest(0, -speed);
});

motorTestStop.addEventListener('click', async () => {
    if (socket) {
        socket.emit('stop_motor_test', {});
    } else {
        await sendHttp('/stop_motor_test', {});
    }
});

setStatus('Connecting...');
fetchStatusOnce().catch(() => {});
initSocket();
