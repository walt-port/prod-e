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
      // Padding around text
      const padding = 12;
      // Calculate size needed for text + padding
      const neededWidth = offsetWidth + padding * 2;
      const neededHeight = offsetHeight + padding * 2;
      setSvgSize({
        width: neededWidth,
        height: neededHeight,
      });

      // Calculate inner perimeter based on needed size
      const rectInnerWidth = neededWidth > 0 ? neededWidth - 2 : 0;
      const rectInnerHeight = neededHeight > 0 ? neededHeight - 2 : 0;
      const perimeter = Math.round(rectInnerWidth * 2 + rectInnerHeight * 2);
      setPathLength(perimeter);
    }
  }, [isEgg]); // Re-measure if text content changes (egg toggle)

  return (
    // Outer container - Keep relative inline-block
    <div className="relative inline-block">
      {/* SVG container - Use outer dimensions for svg width/height */}
      <svg
        width={svgSize.width > 0 ? svgSize.width + 140 : 0} // Use new larger offset
        height={svgSize.height > 0 ? svgSize.height + 140 : 0} // Use new larger offset
        // Expand viewBox even further
        viewBox={`-70 -70 ${svgSize.width > 0 ? svgSize.width + 140 : 0} ${
          svgSize.height > 0 ? svgSize.height + 140 : 0
        }`}
        className="absolute top-[49%] left-1/2 -translate-x-1/2 -translate-y-[49%]"
        style={{ overflow: 'visible' }}
      >
        <defs>
          <linearGradient
            id="logoGradient"
            x1="0%"
            y1="0%"
            x2="100%"
            y2="100%"
            gradientTransform="rotate(0)"
          >
            {/* Using colors from original sketch */}
            <stop offset="0%" style={{ stopColor: '#9ece6a' }} />
            <stop offset="33%" style={{ stopColor: '#f7768e' }} />
            <stop offset="66%" style={{ stopColor: '#bb9af7' }} />
            <stop offset="100%" style={{ stopColor: '#9ece6a' }} />
            {/* Animate the gradient rotation */}
            <animateTransform
              attributeName="gradientTransform"
              type="rotate"
              from="0"
              to="360"
              dur="10s"
              repeatCount="indefinite"
            />
          </linearGradient>
          {/* White Glow Filter - Revised Structure */}
          <filter id="glowFilter" x="-50%" y="-50%" width="200%" height="200%">
            {/* Blur the Source Alpha */}
            <feGaussianBlur in="SourceAlpha" stdDeviation="4" result="blur" />
            {/* Create white flood */}
            <feFlood floodColor="white" result="floodWhite" />
            {/* Mask the white flood with the blurred alpha */}
            <feComposite in="floodWhite" in2="blur" operator="in" result="coloredBlur" />
            {/* Merge original graphic over the colored blur */}
            <feMerge>
              <feMergeNode in="coloredBlur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* Outer Border Rectangle - Apply glow filter */}
        <rect
          id="logoOuterBorderRect"
          x="-70"
          y="-71"
          width={svgSize.width > 0 ? svgSize.width + 140 : 0}
          height={svgSize.height > 0 ? svgSize.height + 140 : 0}
          rx="10"
          fill="none"
          stroke="url(#logoGradient)"
          strokeWidth="2"
          filter="url(#glowFilter)" // Apply the filter
        />

        {/* Inner Border rectangle - Keep original position/size */}
        <rect
          id="logoBorderRect"
          x="1"
          y="1"
          width={svgSize.width > 0 ? svgSize.width - 2 : 0} // Based on original svgSize
          height={svgSize.height > 0 ? svgSize.height - 2 : 0} // Based on original svgSize
          rx="8"
          fill="none"
          stroke="url(#logoGradient)"
          strokeWidth="2"
          style={
            {
              strokeDasharray: pathLength,
              strokeDashoffset: pathLength,
              '--path-length': pathLength,
            } as React.CSSProperties
          }
        />
      </svg>

      {/* Text element - Add ID for CSS animation */}
      <div
        id="logoTextContainer"
        ref={textRef}
        className="font-hermit text-[#c0caf5] cursor-pointer inline-block relative z-10"
        style={{ fontSize: '3.5rem', fontWeight: 'bold' }}
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
