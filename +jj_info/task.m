function task(opts)

TIMER = opts.TIMER;
TRACKER = opts.TRACKER;
STIMULI = opts.STIMULI;
REWARDS = opts.REWARDS;

cstate = 'fixation';

do_once = true;

while ( true )
  
  %   fixation
  if ( isequal(cstate, 'fixation') )
    TRACKER.update_coordinates();
    fix_square = STIMULI.fix_square;
    if ( do_once )
      TIMER.reset_timers( cstate );
      fix_square.reset_targets();
      do_once = false;
    end
    fix_square.draw();
    fix_square.update_targets();
    Screen( 'Flip', opts.WINDOW.index );
    if ( fix_square.duration_met() )
      %   MARK: goto: display_random_vs_info_cues
      cstate = 'display_random_vs_info_cues';
      do_once = true;
    end
    if ( TIMER.duration_met('fixation') )
      %   do something
      break;
    end
  end
  
  %   display_random_vs_info_cues
  if ( isequal(cstate, 'display_random_vs_info_cues') );
    receive_info_cue = STIMULI.receive_info_cue;
    receive_random_cue = STIMULI.receive_random_cue;
    if ( do_once )
      TIMER.reset_timers( cstate );
      receive_info_cue.put( 'center-left' );
      receive_random_cue.put( 'center-right' );
      number = rand();
      do_once = false;
    end
    if ( number < (1/3) )
      receive_info_cue.draw();
      choice_options.kinds = { 'info' };
      choice_options.stimuli = { receive_info_cue };
    elseif ( number < (2/3) )
      receive_random_cue.draw();
      choice_options.kinds = { 'random' };
      choice_options.stimuli = { receive_random_cue };
    else
      receive_info_cue.draw();
      receive_random_cue.draw();
      choice_options.kinds = { 'info', 'random' };
      choice_options.stimuli = { receive_info_cue, receive_random_cue };
    end
    Screen( 'Flip', opts.WINDOW.index );
    if ( TIMER.duration_met(cstate) )
      %   MARK: goto: look_to_random_vs_info
      cstate = 'look_to_random_vs_info';
      do_once = true;
    end
  end
  
  %   look_to_random_vs_info
  if ( isequal(cstate, 'look_to_random_vs_info') )
    TRACKER.update_coordinates();
    if ( do_once )
      TIMER.reset_timers( cstate );
      cellfun( @(x) x.reset_targets(), choice_options.stimuli );
      chosen_option = [];
      do_once = false;
    end    
    for i = 1:numel(choice_options.kinds)
      kind = choice_options.kinds{i};
      cue = choice_options.stimuli{i};
      cue.update_targets();
      if ( cue.duration_met() )
        chosen_option = kind;
        %   MARK: goto: display_info_cues
        cstate = 'display_info_cues';
        do_once = true;
        break;
      end
    end
    return_to_fixation = TIMER.duration_met('look_to_random_vs_info') && ...
      isequal(chosen_option, []);
    if ( return_to_fixation )
      %   MARK: goto: fixation
      cstate = 'fixation';
      do_once = true;
    end
  end
  
  %   display_info_cues
  if ( isequal(cstate, 'display_info_cues') )
    if ( do_once )
      TIMER.reset_timers( cstate );
      number = rand();
      do_once = false;
    end
    if ( isequal(chosen_option, 'info') )
      cues = { STIMULI.info_cue1, STIMULI.info_cue2 };
      possible_rewards = [ REWARDS.info_cue1, REWARDS.info_cue2 ];
    else
      cues = { STIMULI.random_cue1, STIMULI.random_cue2 };
      possible_rewards = REWARDS.random;
    end
    if ( number > .5 )
      cues{1}.draw_frame();
      current_reward = possible_rewards(1);
    else
      cues{2}.draw_frame();
      current_reward = possible_rewards(2);
    end
    Screen( 'Flip', opts.WINDOW.index );
    if ( TIMER.duration_met('display_info_cues') )
      cstate = 'reward';
      do_once = true;
    end
  end
  
  %   reward
  if ( isequal(cstate, 'reward') )
    if ( do_once )
      TIMER.set_durations( cstate, current_reward/1e3 );
      TIMER.reset_timers( cstate );
      %   deliver_reward( current_reward )
      do_once = false;
    end    
    if ( TIMER.duration_met(cstate) )
      cstate = 'fixation';
    end
  end
  
  %   Quit if error in EyeLink
  err = TRACKER.check_recording();
  if ( err ~= 0 ), break; end;
  
  %   Quit if key is pressed
  [key_pressed, ~, ~] = KbCheck();
  if ( key_pressed ), break; end
  
  %   Quit if time exceeds total time
  if ( TIMER.duration_met('task') ), break; end;  
end


end