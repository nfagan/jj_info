function task(opts)

IO =        opts.IO;
META =      opts.META;
TIMER =     opts.TIMER;
TRACKER =   opts.TRACKER;
STIMULI =   opts.STIMULI;
STRUCTURE = opts.STRUCTURE;
REWARDS =   opts.REWARDS;

cstate = 'new_trial';

first_entry = true;

PROGRESS = struct();
DATA = struct();
TRIAL_NUMBER = 0;

errors.no_choice = false;
errors.broke_choice = false;
errors.no_fixation = false;
errors.broke_fixation = false;

block_sequence = STRUCTURE.block_sequence;
block_number = 1;

while ( true )
  
  %   new trial
  if ( isequal(cstate, 'new_trial') )
    if ( first_entry )
      %   RECORD DATA
      if ( TRIAL_NUMBER > 0 )
        tn = TRIAL_NUMBER;
        DATA(tn).trial_number = tn;
        DATA(tn).block_number = block_number;
        DATA(tn).trial_type = trial_type;
        DATA(tn).selected_cue = chosen_option;
        DATA(tn).shown_reward_cue = shown_image;
        DATA(tn).reward_type = rwd_type;
        DATA(tn).reward_size = current_reward;
        DATA(tn).info_location = info_location;
        DATA(tn).random_location = random_location;
        DATA(tn).errors = errors;
        DATA(tn).events = PROGRESS;
      end
      if ( isempty(block_sequence) )
        block_sequence = STRUCTURE.block_sequence;
        block_number = block_number + 1;
      end
      TRIAL_NUMBER = TRIAL_NUMBER + 1;
      PROGRESS = structfun( @(x) NaN, PROGRESS, 'un', false );
      TIMER.reset_timers( cstate );
      if ( ~errors.no_choice && ~errors.broke_choice )
        %   reset variables
        chosen_option = [];
        shown_image = [];
        %   choose a new sequence
        current_sequence_ind = randperm( size(block_sequence, 1) );
        current_sequence = block_sequence( current_sequence_ind(1), : );
        block_sequence( current_sequence_ind(1), : ) = [];
        %   extract trial data from block sequence
        trial_type = current_sequence{1};
        rwd_type = current_sequence{2};
        random_cue_type = current_sequence{3};
        location = current_sequence{4};
        %   determine which stimuli to show, info v. random v. both
        images = STIMULI.images;
        receive_info_cue = STIMULI.receive_info_cue;
        receive_random_cue = STIMULI.receive_random_cue;
        info_cue = STIMULI.info_cue;
        random_cue = STIMULI.random_cue;
        choice_options = struct();
        switch ( trial_type )
          case 'choice'
            info_location = location{1};
            random_location = location{2};
            receive_info_cue.put( info_location );
            receive_random_cue.put( random_location );
            choice_options.kinds = { 'info', 'random' };
            choice_options.stimuli = { receive_info_cue, receive_random_cue };
            info_image_matrix = images.info.(rwd_type).matrices{1};
            info_image_file = images.info.(rwd_type).filenames{1};
            rand_image_matrix = images.random.(random_cue_type).matrices{1};
            rand_image_file = images.random.(random_cue_type).filenames{1};
            info_cue.image = info_image_matrix;
            info_cue.put( info_location );
            random_cue.image = rand_image_matrix;
            random_cue.put( random_location );
          case 'info'
            info_location = location;
            random_location = [];
            receive_info_cue.put( info_location );
            choice_options.kinds = { 'info' };
            choice_options.stimuli = { receive_info_cue };
            info_image_matrix = images.info.(rwd_type).matrices{1};
            info_image_file = images.info.(rwd_type).filenames{1};
            info_cue.image = info_image_matrix;
            info_cue.put( info_location );
          case 'random'
            random_location = location;
            info_location = [];
            receive_random_cue.put( random_location );
            choice_options.kinds = { 'random' };
            choice_options.stimuli = { receive_random_cue };
            rand_image_matrix = images.random.(random_cue_type).matrices{1};
            rand_image_file = images.random.(random_cue_type).filenames{1};
            random_cue.image = rand_image_matrix;
            random_cue.put( random_location );
        end
        %   establish current_reward size
        current_reward = REWARDS.(rwd_type);
      end
      Screen( 'Flip', opts.WINDOW.index );
      first_entry = false;
    end
    if ( TIMER.duration_met('new_trial') )
      %   MARK: goto: fixation
      cstate = 'fixation';
      first_entry = true;
    end
  end
  
  %   fixation
  if ( isequal(cstate, 'fixation') )
    if ( first_entry )
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      TIMER.reset_timers( cstate );
      fix_square = STIMULI.fix_square;
      fix_square.reset_blink();
      fix_square.reset_targets();
      made_look = false;
      errors.broke_fixation = false;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    fix_square.draw();
    fix_square.update_targets();
    if ( fix_square.in_bounds() )
      fix_square.should_blink = false;
      made_look = true;
    else
      fix_square.should_blink = true;
      if ( made_look )
        %   MARK: goto: error
        cstate = 'error';
        errors.broke_fixation = true;
        first_entry = true;
      end
    end
    Screen( 'Flip', opts.WINDOW.index );
    if ( ~errors.broke_fixation )
      if ( fix_square.duration_met() )
        %   MARK: goto: display_random_vs_info_cues
        cstate = 'display_random_vs_info_cues';
        errors.no_fixation = false;
        first_entry = true;
      elseif ( TIMER.duration_met('fixation') )
        %   MARK: goto: new_trial
        errors.no_fixation = true;
        cstate = 'new_trial';
        first_entry = true;
      end
    end
  end
  
  %   error
  if ( isequal(cstate, 'error') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      Screen( 'Flip', opts.WINDOW.index );
      sounds = STIMULI.sounds.error;
      sound( sounds.matrices{1}, sounds.fs{1} );
      first_entry = false;
    end
    if ( TIMER.duration_met('error') )
      %   MARK: goto: iti
      cstate = 'iti';
      first_entry = true;
    end
  end
  
  %   display_random_vs_info_cues
  if ( isequal(cstate, 'display_random_vs_info_cues') );
    if ( first_entry )
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      TIMER.reset_timers( cstate );
      first_entry = false;
    end
    cellfun( @(x) x.draw(), choice_options.stimuli );
    Screen( 'Flip', opts.WINDOW.index );
    if ( TIMER.duration_met(cstate) )
      %   MARK: goto: look_to_random_vs_info
      cstate = 'look_to_random_vs_info';
      first_entry = true;
    end
  end
  
  %   look_to_random_vs_info
  if ( isequal(cstate, 'look_to_random_vs_info') )
    if ( first_entry )
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      TIMER.reset_timers( cstate );
      cellfun( @(x) x.reset_targets(), choice_options.stimuli );
      chosen_option = [];
      made_choice = false;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    if ( ~made_choice )
      for i = 1:numel(choice_options.kinds)
        kind = choice_options.kinds{i};
        cue = choice_options.stimuli{i};
        cue.update_targets();
        if ( cue.in_bounds() )
          choice_options.kinds = { kind };
          choice_options.stimuli = { cue };
          chosen_option = kind;
          made_choice = true;
          break;
        end
      end
    else
      cue.update_targets();
    end
    cellfun( @(x) x.draw(), choice_options.stimuli );
    Screen( 'Flip', opts.WINDOW.index );
    if ( made_choice && ~cue.in_bounds() )
      %   MARK: goto: error
      errors.broke_choice = true;
      errors.no_choice = false;
      cstate = 'error';
      first_entry = true;
    elseif ( TIMER.duration_met('look_to_random_vs_info') )
      %   MARK: goto: error OR display_cues
      if ( ~made_choice )
        errors.no_choice = true;
        errors.broke_choice = false;
        cstate = 'error';
      else
        cstate = 'display_info_cues';
        errors.broke_choice = false;
        errors.no_choice = false;
      end
      first_entry = true;
    end
  end
  
  %   display_info_cues
  if ( isequal(cstate, 'display_info_cues') )
    if ( first_entry )
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      TIMER.reset_timers( cstate );
      first_entry = false;
    end
    if ( isequal(chosen_option, 'info') )
      cue = STIMULI.info_cue;
      shown_image = info_image_file;
    else
      cue = STIMULI.random_cue;
      shown_image = rand_image_file;
    end
    cue.draw();
    Screen( 'Flip', opts.WINDOW.index );
    if ( TIMER.duration_met('display_info_cues') )
      cstate = 'reward';
      first_entry = true;
    end
  end
  
  %   reward
  if ( isequal(cstate, 'reward') )
    if ( first_entry )
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      TIMER.set_durations( cstate, current_reward/1e3 );
      TIMER.reset_timers( cstate );
      sounds = STIMULI.sounds.reward;
      sound( sounds.matrices{1}, sounds.fs{1} );
      %   deliver_reward( current_reward )
      first_entry = false;
    end    
    if ( TIMER.duration_met(cstate) )
      %   MARK: goto: new_trial
      cstate = 'iti';
      first_entry = true;
    end
  end
  
  %   iti
  if ( isequal(cstate, 'iti') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      Screen( 'Flip', opts.WINDOW.index );
      first_entry = false;
    end
    if ( TIMER.duration_met(cstate) )
      %   MARK: goto: new_trial
      cstate = 'new_trial';
      first_entry = true;
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

data = struct();
data.DATA = DATA;
data.META = META;

save( fullfile(IO.data_folder, IO.data_file), 'data' );

end