import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { User } from '@supabase/supabase-js';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;

    // Function to handle session changes
    const handleSession = async () => {
      try {
        // Get initial session
        const { data: { session } } = await supabase.auth.getSession();
        
        // Only update state if component is still mounted
        if (mounted) {
          setUser(session?.user ?? null);
          setLoading(false);
        }
      } catch (error) {
        console.error('Error getting session:', error);
        if (mounted) {
          setUser(null);
          setLoading(false);
        }
      }
    };

    // Initialize session
    handleSession();

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (mounted) {
        setUser(session?.user ?? null);
        // Wait a bit for Supabase to finish processing the auth change
        await new Promise(resolve => setTimeout(resolve, 100));
        setLoading(false);
      }
    });

    // Cleanup
    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const signIn = async (email: string, password: string) => {
    try {
      setLoading(true);
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
    } catch (error) {
      throw error;
    }
  };

  const signInWithGoogle = async () => {
    try {
      setLoading(true);
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: window.location.origin
        }
      });
      if (error) throw error;
    } catch (error) {
      throw error;
    }
  };

  const signUp = async (email: string, password: string, firstName: string, lastName: string, department: string) => {
    try {
      setLoading(true);
      const { error: signUpError, data } = await supabase.auth.signUp({ 
        email, 
        password,
        options: {
          data: {
            first_name: firstName,
            last_name: lastName,
            department
          }
        }
      });
      
      if (signUpError) throw signUpError;

      if (data.user) {
        // Create user profile
        const { error: profileError } = await supabase
          .from('profiles')
          .insert([
            {
              id: data.user.id,
              email,
              first_name: firstName,
              last_name: lastName,
              department,
              avatar_url: `https://api.dicebear.com/7.x/avatars/svg?seed=${data.user.id}`,
            }
          ]);

        if (profileError) {
          // If profile creation fails, delete the user
          await supabase.auth.admin.deleteUser(data.user.id);
          throw profileError;
        }
      }
    } catch (error) {
      throw error;
    }
  };

  const signOut = async () => {
    try {
      setLoading(true);
      await supabase.auth.signOut();
    } catch (error) {
      throw error;
    }
  };

  return {
    user,
    loading,
    signIn,
    signUp,
    signOut,
    signInWithGoogle
  };
}