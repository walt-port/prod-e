import React from 'react';

const InfoBox: React.FC = () => {
  return (
    // Outer container - Use flex to center the inner window
    <div className="h-full w-full flex items-center justify-center p-4">
      {/* Floating window element - Add w/h classes */}
      <div className="w-[90%] h-[90%] flex flex-col bg-[#1f2335] border border-[#414868] rounded-md overflow-hidden shadow-lg">
        {/* Title Bar - Keep inline padding */}
        <div
          className="bg-[#24283b] py-1 text-xs text-gray-400 border-b border-[#414868] flex justify-between items-center font-hermit"
          style={{ paddingLeft: '0.5rem', paddingRight: '0.5rem' }}
        >
          {/* Left side */}
          <div className="flex">
            <span style={{ paddingRight: '0.75rem' }}>File</span>
            <span style={{ paddingRight: '0.75rem' }}>Edit</span>
            <span style={{ paddingRight: '0.75rem' }}>View</span>
            <span>Help</span>
          </div>

          {/* Right side - Revert to inline margins */}
          <div className="flex items-center">
            {/* Divider before minimize */}
            <div className="h-[12px] border-l border-gray-400"></div>
            {/* Minimize span with margin */}
            <span style={{ marginLeft: '0.5rem' }}>_</span>
            {/* Divider with margin */}
            <div
              className="h-[12px] border-l border-gray-400"
              style={{ marginLeft: '0.5rem' }}
            ></div>
            {/* Square span with margin */}
            <span style={{ marginLeft: '0.5rem' }}>□</span>
            {/* Divider with margin */}
            <div
              className="h-[12px] border-l border-gray-400"
              style={{ marginLeft: '0.5rem' }}
            ></div>
            {/* X span with margin */}
            <span style={{ marginLeft: '0.5rem' }}>X</span>
          </div>
        </div>

        {/* Content Area - Use inline padding */}
        <div
          className="flex-grow text-sm text-[#c0caf5] overflow-y-auto font-hermit"
          style={{
            paddingTop: '0.5rem', // Reduced padding (pt-2)
            paddingRight: '1rem', // Keep pr-4
            paddingBottom: '0.5rem', // Reduced padding (pb-2)
            paddingLeft: '1.5rem', // Keep pl-6 equivalent
          }}
        >
          <p className="mb-4">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
            incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
            exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure
            dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
          </p>
          <p className="mb-4">
            Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt
            mollit anim id est laborum. Curabitur pretium tincidunt lacus. Nulla gravida orci a
            odio. Nullam varius, turpis et commodo pharetra, est eros bibendum elit, nec luctus
            magna felis sollicitudin mauris. Integer in mauris eu nibh euismod gravida.
          </p>
          <p>
            Duis ac tellus et risus vulputate vehicula. Donec lobortis risus a elit. Etiam tempor.
            Ut ullamcorper, ligula eu tempor congue, eros est euismod turpis, id tincidunt sapien
            risus a quam. Maecenas fermentum consequat mi. Donec fermentum. Pellentesque malesuada
            nulla a mi. Duis sapien sem, aliquet nec, commodo eget, consequat quis, neque.
          </p>
        </div>

        {/* Status Bar - Setup for scrolling */}
        <div className="border-t border-[#414868] py-1 text-xs text-gray-400 overflow-hidden whitespace-nowrap font-hermit">
          {/* Inner container for scrolling content */}
          <div className="inline-block" id="statusBarContent">
            {/* Content Section 1 */}
            <span style={{ marginLeft: '1rem' }}>👤</span>
            <a
              href="https://waltryan.com"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              waltryan.com
            </a>
            <span style={{ marginLeft: '1rem' }}>💻</span>
            <a
              href="https://waltryan.dev"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              waltryan.dev
            </a>
            <span style={{ marginLeft: '1rem' }}>🔗</span>
            <a
              href="https://github.com/walt-port/prod-e"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              GitHub:prod-e
            </a>
            {/* Divider for visual separation between repeats */}
            <span style={{ marginLeft: '1rem', marginRight: '1rem' }}>|</span>
            {/* Content Section 2 (Duplicate) */}
            <span style={{ marginLeft: '1rem' }}>👤</span>
            <a
              href="https://waltryan.com"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              waltryan.com
            </a>
            <span style={{ marginLeft: '1rem' }}>💻</span>
            <a
              href="https://waltryan.dev"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              waltryan.dev
            </a>
            <span style={{ marginLeft: '1rem' }}>🔗</span>
            <a
              href="https://github.com/walt-port/prod-e"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              GitHub:prod-e
            </a>
            {/* Add trailing space/divider for smoother loop visual */}
            <span style={{ marginLeft: '1rem', marginRight: '1rem' }}>|</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default InfoBox;
