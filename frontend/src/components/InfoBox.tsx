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

        {/* Content Area (Placeholder) */}
        <div className="flex-grow p-4 text-sm text-[#c0caf5] overflow-y-auto">
          Content Area Placeholder
        </div>

        {/* Status Bar (Placeholder) */}
        <div className="border-t border-[#414868] px-2 py-1 text-xs text-gray-400">
          Status Bar Placeholder
        </div>
      </div>
    </div>
  );
};

export default InfoBox;
