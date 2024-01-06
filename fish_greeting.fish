function fish_greeting
    if set -q fish_private_mode
        colorscript random
        echo "fish is running in private mode, history will not be persisted."
    else
        colorscript random
    end
end