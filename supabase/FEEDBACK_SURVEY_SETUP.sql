-- Create Feedback Surveys table
CREATE TABLE IF NOT EXISTS public.feedback_surveys (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    guest_suggestions text,
    improvements text,
    feedback_text text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT feedback_surveys_pkey PRIMARY KEY (id)
);

-- Enable RLS
ALTER TABLE public.feedback_surveys ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only insert their own feedback
CREATE POLICY "Users can insert their own feedback" ON public.feedback_surveys
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Admin can view all feedback
CREATE POLICY "Admins can view all feedback" ON public.feedback_surveys
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND (role = 'admin' OR role = 'staff')
        )
    );

-- RPC Function to submit feedback and award points atomically
-- Final version matching exactly public.profiles schema
CREATE OR REPLACE FUNCTION public.submit_initial_feedback(
    p_guest_suggestions text,
    p_improvements text,
    p_feedback_text text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid;
    v_points_bonus integer := 1500;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- [CRITICAL FIX] Ensure profile exists before proceeding
    -- Matching columns from DATABASE_SCHEMA.sql (no email column)
    INSERT INTO public.profiles (id, role, points)
    VALUES (v_user_id, 'attendee', 0)
    ON CONFLICT (id) DO NOTHING;

    -- 1. Insert feedback
    INSERT INTO public.feedback_surveys (user_id, guest_suggestions, improvements, feedback_text)
    VALUES (v_user_id, p_guest_suggestions, p_improvements, p_feedback_text);

    -- 2. Award points
    UPDATE public.profiles
    SET points = points + v_points_bonus,
        updated_at = now()
    WHERE id = v_user_id;

    -- 3. Log transaction
    INSERT INTO public.points_log (user_id, points_change, reason, type)
    VALUES (v_user_id, v_points_bonus, 'Bono: Encuesta Inicial de Invitados', 'earn');

    RETURN json_build_object('success', true, 'points_awarded', v_points_bonus);
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'message', SQLERRM);
END;
$$;
