/**
 * Format a UTC date string to a localized date string in Europe/Paris timezone
 */
export const formatDateToParis = (dateStr: string | null | undefined): string => {
  if (!dateStr) return '';
  
  try {
    // Parse the date string and force it to be interpreted in UTC
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) {
      console.warn('Invalid date:', dateStr);
      return '';
    }
    
    // Create formatter with explicit timezone
    const formatter = new Intl.DateTimeFormat('fr-FR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      timeZone: 'Europe/Paris'
    });
    
    return formatter.format(date);
  } catch (error) {
    console.warn('Error formatting date:', error);
    return '';
  }
};

/**
 * Format a UTC date string to a localized date string in Europe/Paris timezone with English locale
 */
export const formatDateToParisEN = (dateStr: string | null | undefined): string => {
  if (!dateStr) return '';
  
  try {
    // Parse the date string and force it to be interpreted in UTC
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) {
      console.warn('Invalid date:', dateStr);
      return '';
    }
    
    // Create formatter with explicit timezone
    const formatter = new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      timeZone: 'Europe/Paris'
    });
    
    return formatter.format(date);
  } catch (error) {
    console.warn('Error formatting date:', error);
    return '';
  }
};