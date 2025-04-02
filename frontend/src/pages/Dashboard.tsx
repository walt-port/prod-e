import React, { useEffect, useRef, useState } from 'react';
import AnimatedLogo from '../components/AnimatedLogo';
import InfoBox from '../components/InfoBox';
import InfrastructureDiagram from '../components/InfrastructureDiagram';
import ResourceMonitorPanel from '../components/ResourceMonitorPanel';

const Dashboard: React.FC = () => {
  // <<< State and Ref for Title Sizing >>>
  const titleRef = useRef<HTMLHeadingElement>(null);
  const [titleSvgSize, setTitleSvgSize] = useState({ width: 0, height: 0 });

  // <<< Effect for Title Sizing >>>
  useEffect(() => {
    if (titleRef.current) {
      const { offsetWidth, offsetHeight } = titleRef.current;
      const padding = 12; // Padding around text
      setTitleSvgSize({
        width: offsetWidth + padding * 2,
        height: offsetHeight + padding * 2,
      });
    }
  }, []); // Run once on mount

  return (
    <div
      className="flex flex-col h-screen p-4 border border-[#bb9af7] bg-[#1a1b26]"
      style={{ borderRadius: '0.75rem' }}
    >
      {/* === Title Section with Border === */}
      {/* Wrapper div for positioning */}
      <div className="relative inline-block mx-auto mb-4">
        {' '}
        {/* Center block, add margin below */}
        {/* SVG Border - Positioned absolutely */}
        <svg
          width={titleSvgSize.width}
          height={titleSvgSize.height}
          viewBox={`0 0 ${titleSvgSize.width} ${titleSvgSize.height}`}
          className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
          style={{ overflow: 'visible' }} // Allow potential overflow if needed
        >
          <defs>
            {/* Gradient definition */}
            <linearGradient
              id="titleGradient"
              x1="0%"
              y1="0%"
              x2="100%"
              y2="100%"
              gradientTransform="rotate(0)"
            >
              <stop offset="0%" style={{ stopColor: '#9ece6a' }} />
              <stop offset="33%" style={{ stopColor: '#f7768e' }} />
              <stop offset="66%" style={{ stopColor: '#bb9af7' }} />
              <stop offset="100%" style={{ stopColor: '#9ece6a' }} />
              <animateTransform
                attributeName="gradientTransform"
                type="rotate"
                from="0"
                to="360"
                dur="10s"
                repeatCount="indefinite"
              />
            </linearGradient>
          </defs>
          {/* Border Rectangle */}
          <rect
            x="1"
            y="1"
            width={titleSvgSize.width > 0 ? titleSvgSize.width - 2 : 0}
            height={titleSvgSize.height > 0 ? titleSvgSize.height - 2 : 0}
            rx="10"
            fill="none"
            stroke="url(#titleGradient)"
            strokeWidth="2"
          />
        </svg>
        {/* Title Text - Add Ref */}
        <h1
          ref={titleRef}
          className="text-3xl font-bold text-center text-[#bb9af7] relative z-10" // Added relative z-10
          style={{ textShadow: '0 0 8px rgba(192, 202, 245, 0.4)' }}
        >
          Prod-E Monitoring Dashboard
        </h1>
      </div>
      {/* === End Title Section === */}

      {/* Main Content Area */}
      <div className="flex-grow overflow-hidden" style={{ padding: '1rem' }}>
        {/* Restore grid layout and h-full */}
        <div className="grid grid-cols-2 h-full w-full" style={{ gap: '1rem' }}>
          {/* Panel 1: Restore overflow-y-auto */}
          <div
            className="border border-[#7aa2f7] overflow-y-auto shadow-lg bg-[#1f2335]"
            style={{ borderRadius: '0.5rem', boxShadow: '0 0 12px rgba(122, 162, 247, 0.4)' }}
          >
            <ResourceMonitorPanel />
          </div>

          {/* Panel 2: Restore overflow-y-auto */}
          <div
            className="border border-[#9ece6a] overflow-y-auto shadow-lg bg-[#1f2335] p-4"
            style={{ borderRadius: '0.5rem', boxShadow: '0 0 12px rgba(158, 206, 106, 0.4)' }}
          >
            <InfrastructureDiagram />
            {/* Diagram Placeholder */}
          </div>

          {/* Panel 3: Ensure overflow-y-auto is present */}
          <div
            className="border border-[#e0af68] overflow-y-auto shadow-lg bg-[#1f2335] p-4"
            style={{ borderRadius: '0.5rem', boxShadow: '0 0 12px rgba(224, 175, 104, 0.4)' }}
          >
            <InfoBox />
            {/* InfoBox Placeholder */}
          </div>

          {/* Panel 4: Restore overflow-y-auto */}
          <div
            className="border border-[#bb9af7] overflow-y-auto shadow-lg bg-[#1f2335] flex items-center justify-center p-4"
            style={{ borderRadius: '0.5rem', boxShadow: '0 0 12px rgba(187, 154, 247, 0.4)' }}
          >
            <AnimatedLogo />
            {/* Logo Placeholder */}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
