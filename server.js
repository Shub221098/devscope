const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const cors = require('cors');
const fs = require('fs');

const app = express();
const PORT = 3000;

// Valid scripts that can be executed
const validScripts = [
    'collector.sh',
    'system_stats.sh',
    'top_cpu_processes.sh',
    'analyze_productivity.sh',
    'get_active_window.sh',
    'last_commands_with_timestamps.sh'
];

// Store script outputs in memory
const scriptOutputs = {};

app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

// Endpoint to run scripts
app.post('/run-script', (req, res) => {
    const { script } = req.body;

    // Validate script name
    if (!validScripts.includes(script)) {
        return res.json({ success: false, error: 'Invalid script' });
    }

    const scriptPath = path.join(__dirname, script);

    // Initialize output for this script
    scriptOutputs[script] = {
        status: 'running',
        output: `Starting ${script}...\n`,
        startTime: new Date().toISOString()
    };

    // Run script and capture output
    // For productivity script, use longer timeout (60 seconds)
    const timeout = script === 'analyze_productivity.sh' ? 60000 : 30000;
    exec(`bash ${scriptPath}`, { cwd: __dirname, maxBuffer: 1024 * 1024 * 10, timeout: timeout }, (error, stdout, stderr) => {
        const output = stdout + (stderr ? '\n[STDERR]\n' + stderr : '');
        
        scriptOutputs[script] = {
            status: error ? 'error' : 'completed',
            output: output || 'No output',
            startTime: scriptOutputs[script].startTime,
            endTime: new Date().toISOString(),
            error: error ? error.message : null
        };

        console.log(`[${new Date().toISOString()}] ${script} ${error ? 'failed' : 'completed'}`);
    });

    // Return success immediately with script ID
    res.json({ success: true, message: `${script} started`, script: script });
});

// Endpoint to get script output
app.get('/script-output/:script', (req, res) => {
    const { script } = req.params;

    if (!validScripts.includes(script)) {
        return res.json({ error: 'Invalid script' });
    }

    const output = scriptOutputs[script] || { status: 'not_run', output: '' };
    res.json(output);
});

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

app.listen(PORT, () => {
    console.log(`\n🚀 DevScope Server running at http://localhost:${PORT}`);
    console.log('Open http://localhost:3000 in your browser\n');
});
