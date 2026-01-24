import { useEffect, useState, useRef, useCallback } from 'react';

/**
 * Hook pour gérer les sons de notification
 * Crée le contexte audio au premier appel de playSound() (après geste utilisateur)
 */
export function useNotificationSound() {
  const audioContextRef = useRef<AudioContext | null>(null);
  const masterGainRef = useRef<GainNode | null>(null);
  const oscillatorsRef = useRef<OscillatorNode[]>([]);
  const gainsRef = useRef<GainNode[]>([]);
  const [soundEnabled, setSoundEnabled] = useState(() => {
    const saved = localStorage.getItem('notificationSoundEnabled');
    return saved === null ? true : saved === 'true';
  });

  // Sauvegarder l'état du son
  useEffect(() => {
    localStorage.setItem('notificationSoundEnabled', String(soundEnabled));
  }, [soundEnabled]);

  // Arrêter tous les sons en cours si désactivé
  useEffect(() => {
    if (!soundEnabled && masterGainRef.current) {
      console.log('Sound disabled, stopping all sounds...');
      try {
        // Mute le master gain immédiatement
        const now = audioContextRef.current?.currentTime || 0;
        masterGainRef.current.gain.setValueAtTime(0, now);
      } catch (e) {
        console.error('Error muting master gain:', e);
      }
      
      // Arrêter tous les oscillateurs
      oscillatorsRef.current.forEach(osc => {
        try {
          osc.stop();
        } catch (e) {
          // L'oscillateur a peut-être déjà été arrêté
        }
      });
      oscillatorsRef.current = [];
      gainsRef.current = [];
    }
  }, [soundEnabled]);

  // Créer ou résumer le contexte audio au premier appel
  const ensureAudioContext = useCallback(() => {
    try {
      if (!audioContextRef.current) {
        const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
        audioContextRef.current = ctx;
        
        // Créer un master gain node pour contrôler tous les sons
        if (!masterGainRef.current) {
          const masterGain = ctx.createGain();
          masterGain.connect(ctx.destination);
          masterGainRef.current = masterGain;
        }
        
        console.log('AudioContext created, state:', ctx.state);
      }

      if (audioContextRef.current.state === 'suspended') {
        console.log('AudioContext is suspended, resuming...');
        audioContextRef.current.resume().then(() => {
          console.log('AudioContext resumed, state:', audioContextRef.current?.state);
        }).catch((err) => {
          console.error('Failed to resume AudioContext:', err);
        });
      }

      return audioContextRef.current;
    } catch (error) {
      console.error('Failed to create AudioContext:', error);
      return null;
    }
  }, []);

  const playSound = useCallback(() => {
    if (!soundEnabled) {
      console.log('Sound is disabled');
      return;
    }

    const audioContext = ensureAudioContext();
    if (!audioContext) {
      console.error('AudioContext not available');
      return;
    }

    try {
      console.log('Playing notification sound...');
      const now = audioContext.currentTime;
      
      // Note 1: D5 (587.33 Hz)
      const osc1 = audioContext.createOscillator();
      const gain1 = audioContext.createGain();
      osc1.connect(gain1);
      gain1.connect(masterGainRef.current!);
      
      osc1.frequency.setValueAtTime(587.33, now);
      osc1.type = 'sine';
      gain1.gain.setValueAtTime(0.3, now);
      gain1.gain.exponentialRampToValueAtTime(0.05, now + 0.15);
      
      osc1.start(now);
      osc1.stop(now + 0.15);
      
      // Note 2: A5 (880 Hz)
      const osc2 = audioContext.createOscillator();
      const gain2 = audioContext.createGain();
      osc2.connect(gain2);
      gain2.connect(masterGainRef.current!);
      
      osc2.frequency.setValueAtTime(880, now + 0.15);
      osc2.type = 'sine';
      gain2.gain.setValueAtTime(0.3, now + 0.15);
      gain2.gain.exponentialRampToValueAtTime(0.05, now + 0.3);
      
      osc2.start(now + 0.15);
      osc2.stop(now + 0.3);
      
      // Note 3: C6 (1046.5 Hz)
      const osc3 = audioContext.createOscillator();
      const gain3 = audioContext.createGain();
      osc3.connect(gain3);
      gain3.connect(masterGainRef.current!);
      
      osc3.frequency.setValueAtTime(1046.5, now + 0.3);
      osc3.type = 'sine';
      gain3.gain.setValueAtTime(0.3, now + 0.3);
      gain3.gain.exponentialRampToValueAtTime(0.05, now + 0.6);
      
      osc3.start(now + 0.3);
      osc3.stop(now + 0.6);

      // Stocker les références pour pouvoir les arrêter plus tard
      oscillatorsRef.current = [osc1, osc2, osc3];
      gainsRef.current = [gain1, gain2, gain3];
      
      console.log('Sound played successfully');
    } catch (error) {
      console.error('Error playing notification sound:', error);
    }
  }, [soundEnabled, ensureAudioContext]);

  const toggleSound = () => {
    setSoundEnabled(prev => !prev);
  };

  return {
    soundEnabled,
    toggleSound,
    playSound,
  };
}
