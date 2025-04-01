import React, { useEffect, useRef, useState } from 'react';

interface LoadingTerminalProps {
  command?: string;
  typingSpeed?: number; // Milliseconds per character
  delayBeforeStart?: number; // Milliseconds before typing starts
  onFinished?: () => void;
}

const LoadingTerminal: React.FC<LoadingTerminalProps> = ({
  command = 'exec prod-e',
  typingSpeed = 150,
  delayBeforeStart = 500,
  onFinished,
}) => {
  const [displayedText, setDisplayedText] = useState('');
  const [showCursor, setShowCursor] = useState(true);

  // Refs for timer IDs
  const startTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const typingIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const finishTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  // Ref to track if finish logic has been initiated
  const isFinishingRef = useRef<boolean>(false);

  useEffect(() => {
    // console.log('LoadingTerminal EFFECT RUN');
    isFinishingRef.current = false;
    if (startTimeoutRef.current) clearTimeout(startTimeoutRef.current);
    if (typingIntervalRef.current) clearInterval(typingIntervalRef.current);
    if (finishTimeoutRef.current) clearTimeout(finishTimeoutRef.current);

    if (!command) {
      // console.log('LoadingTerminal: No command, finishing immediately.');
      if (onFinished) onFinished();
      return;
    }

    // console.log(`LoadingTerminal: Starting with command: ${command}`);
    startTimeoutRef.current = setTimeout(() => {
      // console.log('LoadingTerminal: Start timeout finished, starting typing interval.');
      typingIntervalRef.current = setInterval(() => {
        // console.log(`LoadingTerminal: Interval TICK at ${Date.now()}`);
        setDisplayedText(prev => {
          if (prev.length >= command.length) {
            if (typingIntervalRef.current) clearInterval(typingIntervalRef.current);
            return prev;
          }
          const nextText = command.substring(0, prev.length + 1);
          if (nextText.length >= command.length && !isFinishingRef.current) {
            isFinishingRef.current = true;
            // console.log('LoadingTerminal: Typing finished.');
            if (typingIntervalRef.current) clearInterval(typingIntervalRef.current);
            setShowCursor(false);
            if (onFinished) {
              finishTimeoutRef.current = setTimeout(() => {
                // console.log('LoadingTerminal: Would call onFinished now (but commented out for debugging)');
                onFinished();
              }, 1500);
            }
          }
          return nextText;
        });
      }, typingSpeed);
    }, delayBeforeStart);

    return () => {
      // console.log('LoadingTerminal: EFFECT CLEANUP');
      if (startTimeoutRef.current) clearTimeout(startTimeoutRef.current);
      if (typingIntervalRef.current) clearInterval(typingIntervalRef.current);
      if (finishTimeoutRef.current) clearTimeout(finishTimeoutRef.current);
    };
  }, [command, typingSpeed, delayBeforeStart, onFinished]);

  return (
    <div
      className="bg-[#1a1b26] border border-[#414868] rounded-lg px-6 py-4
                 font-mono text-[#c0caf5] outline-none z-50"
      style={{
        position: 'fixed',
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%)',
        width: '384px',
        height: '112px',
        overflow: 'hidden',
      }}
    >
      {/* Line 1 */}
      <div className="mb-2">
        <span className="text-[#bb9af7]">❯~</span>
      </div>
      {/* Line 2 */}
      <div>
        <span className="text-[#bb9af7]">❯</span>
        <span className="ml-2 whitespace-pre whitespace-nowrap">{displayedText}</span>
        {showCursor && (
          <span
            className="ml-1 inline-block w-2 h-4 bg-[#c0caf5] animate-pulse align-middle"
            style={{ animationDuration: '1s' }}
          ></span>
        )}
      </div>
    </div>
  );
};

export default LoadingTerminal;
