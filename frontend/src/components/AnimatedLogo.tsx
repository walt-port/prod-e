import React, { useEffect, useRef, useState } from 'react';

const AnimatedLogo: React.FC = () => {
  const [isEgg, setIsEgg] = useState(false);
  const textRef = useRef<HTMLDivElement>(null); // Ref to measure text size
  const [svgSize, setSvgSize] = useState({ width: 0, height: 0 }); // State for SVG dimensions
  const [pathLength, setPathLength] = useState(0); // State for perimeter length

  const toggleEgg = () => {
    setIsEgg(!isEgg);
  };

  // Effect to measure the text element size after render/update
  useEffect(() => {
    if (textRef.current) {
      const { offsetWidth, offsetHeight } = textRef.current;
      // Restore padding to 12
      const padding = 12;
      const newWidth = offsetWidth + padding * 2 + 8;
      const newHeight = offsetHeight + padding * 2;
      setSvgSize({
        // Add extra horizontal padding
        width: newWidth,
        height: newHeight,
      });

      // Calculate perimeter
      const rectWidth = newWidth > 0 ? newWidth - 2 : 0;
      const rectHeight = newHeight > 0 ? newHeight - 2 : 0;
      const perimeter = Math.round(rectWidth * 2 + rectHeight * 2);
      setPathLength(perimeter);
    }
  }, [isEgg]); // Re-measure if text content changes (egg toggle)

  return (
    // Outer container - Keep relative inline-block
    <div className="relative inline-block">
      {/* SVG container - Adjust vertical alignment */}
      <svg
        width={svgSize.width}
        height={svgSize.height}
        className="absolute top-[49%] left-1/2 -translate-x-1/2 -translate-y-[47%]"
      >
        <defs>
          <linearGradient id="logoGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            {/* Using colors from original sketch */}
            <stop offset="0%" style={{ stopColor: '#9ece6a' }} />
            <stop offset="33%" style={{ stopColor: '#f7768e' }} />
            <stop offset="66%" style={{ stopColor: '#bb9af7' }} />
            <stop offset="100%" style={{ stopColor: '#9ece6a' }} />
          </linearGradient>
        </defs>

        {/* Border rectangle - Apply dynamic dasharray/offset */}
        <rect
          id="logoBorderRect"
          x="1"
          y="1"
          width={svgSize.width > 0 ? svgSize.width - 2 : 0}
          height={svgSize.height > 0 ? svgSize.height - 2 : 0}
          rx="8"
          fill="none"
          stroke="url(#logoGradient)"
          strokeWidth="2"
          style={
            {
              strokeDasharray: pathLength,
              strokeDashoffset: pathLength, // Start fully dashed (invisible)
              '--path-length': pathLength, // Pass length as CSS variable
            } as React.CSSProperties
          } // Cast required for custom properties
        />
      </svg>

      {/* Text element - assign ref, use inline-block for measurement */}
      <div
        ref={textRef}
        className="font-hermit text-[#c0caf5] cursor-pointer inline-block relative z-10" // Added z-10 to be above SVG
        style={{ fontSize: '3.5rem', fontWeight: 'bold' }} // Increased font size
        onClick={toggleEgg}
      >
        <span>prod-</span>
        {/* Egg color from original sketch: #9ece6a (green) */}
        <span style={{ color: isEgg ? '#9ece6a' : 'inherit' }}>{isEgg ? '🥚' : 'e'}</span>
      </div>
    </div>
  );
};

export default AnimatedLogo;
