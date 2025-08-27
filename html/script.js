let currentData = null;
let currentTab = 'main';

// Main event listener for NUI messages
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openBusNUI':
            openInterface(data.data);
            break;
        case 'forceClose':
            closeInterface();
            break;
    }
});

// Enhanced ESC key handling
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeInterface();
    }
});

// Click outside to close
document.addEventListener('click', function(event) {
    if (event.target.classList.contains('interface-backdrop')) {
        closeInterface();
    }
});

// Main function to open the interface
function openInterface(data) {
    currentData = data;
    
    // Update status dashboard
    updateStatusDashboard(data);
    
    // Update all tabs content
    updateMainTab(data);
    updatePassengersTab(data);
    updateStationsTab(data);
    updateRouteTab(data);
    updateStatsTab(data);
    
    // Show interface
    document.getElementById('busInterface').style.display = 'flex';
    
    // Add animation
    setTimeout(() => {
        document.getElementById('busInterface').style.opacity = '1';
    }, 10);
}

// Close interface function
function closeInterface() {
    const interface = document.getElementById('busInterface');
    interface.style.opacity = '0';
    
    setTimeout(() => {
        interface.style.display = 'none';
        sendCallback('closeNUI', {});
    }, 200);
}

// Update status dashboard
function updateStatusDashboard(data) {
    document.getElementById('workStatus').textContent = data.isWorking ? 'On Duty' : 'Off Duty';
    document.getElementById('passengerCount').textContent = data.activePassengers || 0;
    document.getElementById('deliveredCount').textContent = data.totalDelivered || 0;
    document.getElementById('efficiencyRate').textContent = (data.jobStats?.efficiency || 0) + '%';
}

// Update main tab
function updateMainTab(data) {
    const mainActions = document.getElementById('mainActions');
    const quickInfo = document.getElementById('quickInfo');
    
    mainActions.innerHTML = '';
    
    if (!data.isWorking) {
        // Start Job Action
        mainActions.innerHTML += createActionCard({
            title: 'Start Bus Job',
            description: 'Begin your bus route and start earning money. Choose from available routes and begin transporting passengers.',
            icon: 'fas fa-play',
            action: 'startJob',
            type: 'success'
        });
    } else {
        if (!data.hasRentedBus) {
            // Rent Bus Action
            mainActions.innerHTML += createActionCard({
                title: 'Rent Bus Vehicle',
                description: `Rent a bus for $${data.rentalPrice}. This is required to start picking up passengers.`,
                icon: 'fas fa-key',
                action: 'rentBus',
                type: 'primary'
            });
        }
        
        // Finish Job Action
        mainActions.innerHTML += createActionCard({
            title: 'Complete Shift',
            description: 'Return your bus and complete your current shift. You will receive completion bonuses.',
            icon: 'fas fa-flag-checkered',
            action: 'finishJob',
            type: 'warning'
        });
        
        // Cancel Job Action
        mainActions.innerHTML += createActionCard({
            title: 'Cancel Job',
            description: 'Cancel your current job. Warning: No refund will be provided for bus rental.',
            icon: 'fas fa-times',
            action: 'cancelJob',
            type: 'danger'
        });
    }
    
    // Quick Info Section
    if (data.currentRoute) {
        quickInfo.innerHTML = `
            <h4><i class="fas fa-info-circle"></i> Current Route Information</h4>
            <div class="detail-grid">
                <div class="detail-item">
                    <span class="detail-label">Route Name</span>
                    <span class="detail-value">${data.currentRoute.name}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Stations</span>
                    <span class="detail-value">${data.currentRoute.stationCount} stations</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Status</span>
                    <span class="detail-value">${data.hasRentedBus ? 'In Progress' : 'Waiting for Bus'}</span>
                </div>
            </div>
        `;
    } else {
        quickInfo.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-bus"></i>
                <h4>No Active Route</h4>
                <p>Start a job to see route information and begin earning money.</p>
            </div>
        `;
    }
}

// Update passengers tab
function updatePassengersTab(data) {
    const passengerList = document.getElementById('passengerList');
    const navigateBtn = document.getElementById('navigateBtn');
    
    if (!data.passengerList || data.passengerList.length === 0) {
        passengerList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-users"></i>
                <h4>No Passengers Aboard</h4>
                <p>Visit station markers to pick up passengers and start earning money.</p>
            </div>
        `;
        navigateBtn.disabled = true;
    } else {
        navigateBtn.disabled = false;
        
        passengerList.innerHTML = data.passengerList.map(passenger => `
            <div class="passenger-item ${passenger.isNearest ? 'nearest' : ''}">
                <div class="passenger-header">
                    <div class="passenger-name">
                        <i class="fas fa-map-marker-alt"></i>
                        ${passenger.destination}
                        ${passenger.isNearest ? '<span class="passenger-badge nearest">Nearest</span>' : ''}
                    </div>
                    <button class="navigate-btn" onclick="navigateToDestination('${passenger.destination}')">
                        <i class="fas fa-navigation"></i> Navigate
                    </button>
                </div>
                <div class="passenger-details">
                    <div class="detail-item">
                        <span class="detail-label">Category</span>
                        <span class="detail-value">${passenger.category}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Fare</span>
                        <span class="detail-value">$${passenger.fare}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Distance</span>
                        <span class="detail-value">${passenger.distance}m</span>
                    </div>
                </div>
            </div>
        `).join('');
    }
}

// Update stations tab
function updateStationsTab(data) {
    const stationList = document.getElementById('stationList');
    
    if (!data.stationList || data.stationList.length === 0) {
        stationList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-map-marker-alt"></i>
                <h4>No Active Stations</h4>
                <p>Start a job to see assigned pickup stations.</p>
            </div>
        `;
    } else {
        stationList.innerHTML = data.stationList.map(station => `
            <div class="station-item">
                <div class="station-header">
                    <div class="station-name">
                        <i class="fas fa-bus-alt"></i>
                        ${station.name}
                        <span class="station-badge ${station.active ? 'active' : 'completed'}">
                            ${station.active ? 'Active' : 'Completed'}
                        </span>
                    </div>
                </div>
                <div class="station-details">
                    <div class="detail-item">
                        <span class="detail-label">Description</span>
                        <span class="detail-value">${station.description}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Distance</span>
                        <span class="detail-value">${station.distance}m</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Status</span>
                        <span class="detail-value">${station.active ? 'Waiting for pickup' : 'Passengers picked up'}</span>
                    </div>
                </div>
            </div>
        `).join('');
    }
}

// Update route tab
function updateRouteTab(data) {
    const routeInfo = document.getElementById('routeInfo');
    
    if (data.currentRoute) {
        routeInfo.innerHTML = `
            <div class="route-card">
                <h4><i class="fas fa-route"></i> Route Details</h4>
                <div class="detail-grid">
                    <div class="detail-item">
                        <span class="detail-label">Route Name</span>
                        <span class="detail-value">${data.currentRoute.name}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Total Stations</span>
                        <span class="detail-value">${data.currentRoute.stationCount}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Active Passengers</span>
                        <span class="detail-value">${data.activePassengers}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Delivered</span>
                        <span class="detail-value">${data.totalDelivered}</span>
                    </div>
                </div>
            </div>
            
            ${data.nearestDestination ? `
                <div class="route-card">
                    <h4><i class="fas fa-navigation"></i> Nearest Destination</h4>
                    <div class="detail-grid">
                        <div class="detail-item">
                            <span class="detail-label">Destination</span>
                            <span class="detail-value">${data.nearestDestination.name}</span>
                        </div>
                        <div class="detail-item">
                            <span class="detail-label">Distance</span>
                            <span class="detail-value">${data.nearestDestination.distance}m</span>
                        </div>
                    </div>
                    <div style="margin-top: 1rem;">
                        <button class="action-btn navigate" onclick="navigateToNearest()">
                            <i class="fas fa-navigation"></i>
                            Set GPS to Nearest
                        </button>
                    </div>
                </div>
            ` : ''}
        `;
    } else {
        routeInfo.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-route"></i>
                <h4>No Active Route</h4>
                <p>Start a job to see detailed route information and navigation options.</p>
            </div>
        `;
    }
}

// Update stats tab
function updateStatsTab(data) {
    const statsContent = document.getElementById('statsContent');
    
    if (data.jobStats) {
        statsContent.innerHTML = `
            <div class="stat-card">
                <h4><i class="fas fa-chart-bar"></i> Current Session Statistics</h4>
                <div class="stat-grid">
                    <div class="stat-item">
                        <div class="stat-value">${data.totalDelivered}</div>
                        <div class="stat-label">Passengers Delivered</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-value">${data.jobStats.stationsVisited}</div>
                        <div class="stat-label">Stations Visited</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-value">${data.jobStats.efficiency}%</div>
                        <div class="stat-label">Efficiency Rate</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-value">$${data.jobStats.earnings}</div>
                        <div class="stat-label">Earnings</div>
                    </div>
                </div>
            </div>
            
            <div class="stat-card">
                <h4><i class="fas fa-trophy"></i> Performance Metrics</h4>
                <div class="detail-grid">
                    <div class="detail-item">
                        <span class="detail-label">Job Status</span>
                        <span class="detail-value">${data.hasRentedBus ? 'Active' : 'Preparing'}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Route Progress</span>
                        <span class="detail-value">${data.currentRoute ? Math.floor((data.jobStats.stationsVisited / data.currentRoute.stationCount) * 100) : 0}%</span>
                    </div>
                </div>
            </div>
        `;
    } else {
        statsContent.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-chart-bar"></i>
                <h4>No Statistics Available</h4>
                <p>Start working to see your performance statistics and earnings data.</p>
            </div>
        `;
    }
}

// Helper function to create action cards
function createActionCard(action) {
    return `
        <div class="main-action-card" onclick="performAction('${action.action}')">
            <h4><i class="${action.icon}"></i> ${action.title}</h4>
            <p>${action.description}</p>
        </div>
    `;
}

// Tab switching function
function switchTab(tabName) {
    // Remove active class from all tabs and panels
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    document.querySelectorAll('.tab-panel').forEach(panel => panel.classList.remove('active'));
    
    // Add active class to selected tab and panel
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    document.getElementById(`${tabName}-tab`).classList.add('active');
    
    currentTab = tabName;
}

// Action functions
function performAction(action) {
    sendCallback(action, {});
}

function navigateToNearest() {
    sendCallback('navigateToNearest', {});
}

function navigateToDestination(destination) {
    sendCallback('navigateToDestination', { destination: destination });
}

function refreshData() {
    const refreshBtn = document.querySelector('.refresh-btn');
    refreshBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
    
    sendCallback('refreshData', {});
    
    setTimeout(() => {
        refreshBtn.innerHTML = '<i class="fas fa-sync-alt"></i>';
    }, 1000);
}

// Helper function to send callbacks to Lua
function sendCallback(callback, data) {
    fetch(`https://${GetParentResourceName()}/${callback}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(resp => {
        // Handle response if needed
    }).catch(err => {
        console.log('Callback error:', err);
    });
}

// Helper function to get parent resource name
function GetParentResourceName() {
    if (window.location.hostname === 'nui-img' || window.location.hostname.startsWith('cfx-nui-')) {
        return window.location.pathname.split('/')[1];
    }
    return 'busjob';
}

// Initialize interface
document.addEventListener('DOMContentLoaded', function() {
    // Set initial tab
    switchTab('main');
});