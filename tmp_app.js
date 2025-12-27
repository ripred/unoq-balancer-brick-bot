let socket;
let pollTimer = null;
const statusEl = document.getElementById('status');
const errorEl = document.getElementById('error-container');

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

const setpointEl = document.getElementById('setpoint');
const setpointApply = document.getElementById('setpoint-apply');

const imuModel = document.getElementById('imu-model');
const imuApply = document.getElementById('imu-apply');

const axisMode = document.getElementById('axis-mode');
const axisApply = document.getElementById('axis-apply');

const axisSign = document.getElementById('axis-sign');
const axisSignApply = document.getElementById('axis-sign-apply');

const runMode = document.getElementById('run-mode');
const modeApply = document.getElementById('mode-apply');

const kickAngle = document.getElementById('kick-angle');
const kickApply = document.getElementById('kick-apply');

const chart = document.getElementById('chart');
const chartCtx = chart.getContext('2d');
const wire = document.getElementById('wireframe');
const wireCtx = wire.getContext('2d');

const angleHistory = [];
const MAX_POINTS = 200;

const UI_ANGLE_SCALE = 6.0;

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
    chartCtx.clearRect(0, 0, chart.width, chart.height);
    chartCtx.strokeStyle = '#0b7a75';
    chartCtx.beginPath();
    angleHistory.forEach((v, i) => {
        const x = (i / (MAX_POINTS - 1)) * chart.width;
        const y = chart.height / 2 - (v * UI_ANGLE_SCALE);
        if (i === 0) chartCtx.moveTo(x, y);
        else chartCtx.lineTo(x, y);
    });
    chartCtx.stroke();
}

function drawWireframe(angle) {
    wireCtx.clearRect(0, 0, wire.width, wire.height);

    const scaled = angle * (UI_ANGLE_SCALE / 2);
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

    wireCtx.strokeStyle = '#333';
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
    wireCtx.lineTo(pivotX, pivotY - wheelR + 6);
    wireCtx.stroke();

    wireCtx.beginPath();
    wireCtx.arc(pivotX, pivotY, wheelR, 0, Math.PI * 2);
    wireCtx.stroke();

    wireCtx.beginPath();
    wireCtx.moveTo(pivotX - 140, groundY);
    wireCtx.lineTo(pivotX + 140, groundY);
    wireCtx.stroke();
}

function applyConfig(cfg) {
    pidP.value = cfg.pid.p;
    pidI.value = cfg.pid.i;
    pidD.value = cfg.pid.d;
    setpointEl.value = cfg.setpoint;
    imuModel.value = cfg.imu_model;
    axisMode.value = cfg.axis_mode || 'pitch';
    axisSign.value = String(cfg.axis_sign || 1);
    runMode.value = cfg.mode === 'real' ? 'real' : 'sim';
    modeEl.textContent = cfg.mode;
    imuEl.textContent = cfg.imu_model;
}

function updateTelemetry(t) {
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
    if (socket) {
        socket.emit('kick', payload);
    } else {
        await sendHttp('/kick', payload);
    }
});

setStatus('Connecting...');
fetchStatusOnce().catch(() => {});
initSocket();
