import React from 'react';

const InfoBox: React.FC = () => {
  return (
    // Outer container to fill the panel space, add padding
    <div className="h-full w-full p-4">
      {/* Floating window element */}
      <div className="h-full w-full flex flex-col bg-[#1f2335] border border-[#414868] rounded-md overflow-hidden">
        {/* Title Bar (Placeholder) */}
        <div className="bg-[#24283b] px-2 py-1 text-xs text-gray-400 border-b border-[#414868]">
          Title Bar Placeholder
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
