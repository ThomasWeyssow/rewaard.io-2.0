import { useState } from 'react';
import { supabase } from '../lib/supabase';

export function useStorage() {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const uploadHeroBanner = async (file: File): Promise<string> => {
    try {
      setUploading(true);
      setError(null);

      // Vérifier la taille du fichier (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        throw new Error('L\'image ne doit pas dépasser 5MB');
      }

      // Vérifier le type MIME
      if (!file.type.match(/^image\/(jpeg|png|gif|webp)$/)) {
        throw new Error('Type de fichier non supporté. Veuillez utiliser une image au format JPG, PNG, GIF ou WebP.');
      }

      // Générer un nom de fichier unique
      const ext = file.name.split('.').pop()?.toLowerCase() || 'png';
      const fileName = `hero-banner-${Date.now()}.${ext}`;

      // Supprimer l'ancien fichier s'il existe
      const { data: existingFiles } = await supabase.storage
        .from('hero-program')
        .list();

      if (existingFiles?.length) {
        await supabase.storage
          .from('hero-program')
          .remove(existingFiles.map(f => f.name));
      }

      // Upload l'image
      const { data, error } = await supabase.storage
        .from('hero-program')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false,
          contentType: file.type
        });

      if (error) throw error;

      // Récupérer l'URL publique
      const { data: { publicUrl } } = supabase.storage
        .from('hero-program')
        .getPublicUrl(data.path);

      return publicUrl;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Une erreur est survenue lors de l\'upload');
      setError(error);
      throw error;
    } finally {
      setUploading(false);
    }
  };

  const uploadProfilePhoto = async (file: File, userId: string): Promise<string> => {
    try {
      setUploading(true);
      setError(null);

      // Vérifier la taille du fichier (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        throw new Error('L\'image ne doit pas dépasser 5MB');
      }

      // Vérifier le type MIME
      if (!file.type.match(/^image\/(jpeg|png|gif|webp)$/)) {
        throw new Error('Type de fichier non supporté. Veuillez utiliser une image au format JPG, PNG, GIF ou WebP.');
      }

      // Générer un nom de fichier unique avec l'ID de l'utilisateur
      const ext = file.name.split('.').pop()?.toLowerCase() || 'png';
      const fileName = `${userId}/avatar-${Date.now()}.${ext}`;

      // Supprimer les anciens fichiers s'ils existent
      const { data: existingFiles } = await supabase.storage
        .from('profile-images')
        .list(userId);

      if (existingFiles?.length) {
        await supabase.storage
          .from('profile-images')
          .remove(existingFiles.map(f => `${userId}/${f.name}`));
      }

      // Upload l'image
      const { data, error } = await supabase.storage
        .from('profile-images')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false,
          contentType: file.type
        });

      if (error) throw error;

      // Récupérer l'URL publique
      const { data: { publicUrl } } = supabase.storage
        .from('profile-images')
        .getPublicUrl(data.path);

      return publicUrl;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Une erreur est survenue lors de l\'upload');
      setError(error);
      throw error;
    } finally {
      setUploading(false);
    }
  };

  const uploadLogo = async (file: File): Promise<string> => {
    try {
      setUploading(true);
      setError(null);

      // Vérifier la taille du fichier (max 2MB)
      if (file.size > 2 * 1024 * 1024) {
        throw new Error('Le logo ne doit pas dépasser 2MB');
      }

      // Vérifier le type MIME
      if (!file.type.match(/^image\/(png|svg\+xml)$/)) {
        throw new Error('Type de fichier non supporté. Veuillez utiliser une image au format PNG ou SVG.');
      }

      // Générer un nom de fichier unique
      const ext = file.name.split('.').pop()?.toLowerCase() || 'png';
      const fileName = `logo-${Date.now()}.${ext}`;

      // Supprimer l'ancien logo s'il existe
      const { data: existingFiles } = await supabase.storage
        .from('hero-program')
        .list();

      const existingLogo = existingFiles?.find(f => f.name.startsWith('logo-'));
      if (existingLogo) {
        await supabase.storage
          .from('hero-program')
          .remove([existingLogo.name]);
      }

      // Upload le logo
      const { data, error } = await supabase.storage
        .from('hero-program')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false,
          contentType: file.type
        });

      if (error) throw error;

      // Récupérer l'URL publique
      const { data: { publicUrl } } = supabase.storage
        .from('hero-program')
        .getPublicUrl(data.path);

      return publicUrl;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Une erreur est survenue lors de l\'upload');
      setError(error);
      throw error;
    } finally {
      setUploading(false);
    }
  };

  const uploadFavicon = async (file: File): Promise<string> => {
    try {
      setUploading(true);
      setError(null);

      // Vérifier la taille du fichier (max 1MB)
      if (file.size > 1024 * 1024) {
        throw new Error('Le favicon ne doit pas dépasser 1MB');
      }

      // Vérifier le type MIME
      if (!file.type.match(/^image\/(x-icon|png)$/)) {
        throw new Error('Type de fichier non supporté. Veuillez utiliser une image au format ICO ou PNG.');
      }

      // Générer un nom de fichier unique
      const ext = file.name.split('.').pop()?.toLowerCase() || 'ico';
      const fileName = `favicon-${Date.now()}.${ext}`;

      // Supprimer l'ancien favicon s'il existe
      const { data: existingFiles } = await supabase.storage
        .from('hero-program')
        .list();

      const existingFavicon = existingFiles?.find(f => f.name.startsWith('favicon-'));
      if (existingFavicon) {
        await supabase.storage
          .from('hero-program')
          .remove([existingFavicon.name]);
      }

      // Upload le favicon
      const { data, error } = await supabase.storage
        .from('hero-program')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false,
          contentType: file.type
        });

      if (error) throw error;

      // Récupérer l'URL publique
      const { data: { publicUrl } } = supabase.storage
        .from('hero-program')
        .getPublicUrl(data.path);

      return publicUrl;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Une erreur est survenue lors de l\'upload');
      setError(error);
      throw error;
    } finally {
      setUploading(false);
    }
  };

  return {
    uploading,
    error,
    uploadHeroBanner,
    uploadProfilePhoto,
    uploadLogo,
    uploadFavicon
  };
}