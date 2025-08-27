let currentMenuData = null;

// Icon mapping for different actions
const iconMap = {
    'play': 'fas fa-play',
    'key': 'fas fa-key',
    'info-circle': 'fas fa-info-circle',
    'users': 'fas fa-users',
    'flag-checkered': 'fas fa-flag-checkered',
    'times': 'fas fa-times',
    'start': 'fas fa-play',
    'rent': 'fas fa-key',
    'info': 'fas fa-info-circle',
    'passengers': 'fas fa-users',
    'finish': 'fas fa-flag-checkered',
    'cancel': 'fas fa-times'
};

// Listen for messages from the game
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.type === 'openMenu') {
        openMenu(data.data);
    } else if (data.type === 'closeMenu') {
        closeMenu();
    }
});

// Open menu with data
function openMenu(menuData) {
    currentMenuData = menuData;
    
    // Update menu title and subtitle
    document.querySelector('.menu-title').textContent = menuData.title || 'Bus Job Menu';
    document.querySelector('.menu-subtitle').textContent = menuData.subtitle || 'Select an option';
    
    // Clear existing menu items
    const menuItemsContainer = document.getElementById('menu-items');
    menuItemsContainer.innerHTML = '';
    
    // Create menu items
    menuData.items.forEach((item, index) => {
        const menuItem = createMenuItem(item, index);
        menuItemsContainer.appendChild(menuItem);
    });
    
    // Show menu with animation
    const menuContainer = document.getElementById('menu-container');
    menuContainer.classList.remove('hidden');
    
    // Focus on first item
    setTimeout(() => {
        const firstItem = menuItemsContainer.querySelector('.menu-item');
        if (firstItem) {
            firstItem.focus();
        }
    }, 100);
}

// Create a menu item element
function createMenuItem(item, index) {
    const menuItem = document.createElement('div');
    menuItem.className = 'menu-item';
    menuItem.style.animationDelay = `${index * 0.05}s`;
    menuItem.tabIndex = 0;
    
    // Get icon class
    const iconClass = iconMap[item.icon] || 'fas fa-circle';
    
    menuItem.innerHTML = `
        <div class="item-content">
            <div class="item-icon">
                <i class="${iconClass}"></i>
            </div>
            <div class="item-text">
                <div class="item-title">${item.title}</div>
                <div class="item-description">${item.description}</div>
            </div>
            <div class="item-arrow">
                <i class="fas fa-chevron-right"></i>
            </div>
        </div>
    `;
    
    // Add click event
    menuItem.addEventListener('click', () => {
        selectMenuItem(item);
    });
    
    // Add keyboard events
    menuItem.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            selectMenuItem(item);
        } else if (e.key === 'Escape') {
            closeMenu();
        } else if (e.key === 'ArrowDown') {
            e.preventDefault();
            focusNextItem(menuItem);
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            focusPreviousItem(menuItem);
        }
    });
    
    // Add hover effects
    menuItem.addEventListener('mouseenter', () => {
        menuItem.style.transform = 'translateY(-2px)';
    });
    
    menuItem.addEventListener('mouseleave', () => {
        menuItem.style.transform = 'translateY(0)';
    });
    
    return menuItem;
}

// Select a menu item
function selectMenuItem(item) {
    // Add click animation
    const clickedItem = event.currentTarget;
    clickedItem.style.transform = 'scale(0.98)';
    
    setTimeout(() => {
        clickedItem.style.transform = '';
        
        // Send action to game
        fetch(`https://${GetParentResourceName()}/menuAction`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: item.action,
                id: item.id,
                item: item
            })
        }).then(() => {
            closeMenu();
        }).catch((error) => {
            console.error('Error sending menu action:', error);
            closeMenu();
        });
    }, 100);
}

// Close menu
function closeMenu() {
    const menuContainer = document.getElementById('menu-container');
    menuContainer.classList.add('hidden');
    
    // Send close event to game
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).catch((error) => {
        console.error('Error sending close menu:', error);
    });
}

// Focus navigation
function focusNextItem(currentItem) {
    const items = Array.from(document.querySelectorAll('.menu-item'));
    const currentIndex = items.indexOf(currentItem);
    const nextIndex = (currentIndex + 1) % items.length;
    items[nextIndex].focus();
}

function focusPreviousItem(currentItem) {
    const items = Array.from(document.querySelectorAll('.menu-item'));
    const currentIndex = items.indexOf(currentItem);
    const previousIndex = currentIndex === 0 ? items.length - 1 : currentIndex - 1;
    items[previousIndex].focus();
}

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeMenu();
    }
});

// Prevent context menu
document.addEventListener('contextmenu', (e) => {
    e.preventDefault();
});

// Helper function to get resource name (for NUI callback URLs)
function GetParentResourceName() {
    return window.invokeNative ? window.invokeNative('GetParentResourceName') : 'busjob';
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    console.log('Bus Job NUI Interface Loaded');
    
    // Initially hide menu
    const menuContainer = document.getElementById('menu-container');
    menuContainer.classList.add('hidden');
});