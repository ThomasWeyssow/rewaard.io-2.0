import React, { useState } from 'react';
import { AlertCircle, Upload, Image } from 'lucide-react';
import { useStorage } from '../../hooks/useStorage';
import { useSettings } from '../../hooks/useSettings';

export function LogoSettings() {
  const [error, setError] = useState<string | null>(null);
  const { uploadLogo, uploadFavicon, uploading } = useStorage();
  const { settings, updateLogoUrl, updateFaviconUrl } = useSettings();
  
  const handleLogoUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      setError(null);
      const logoUrl = await uploadLogo(file);
      await updateLogoUrl(logoUrl);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Une erreur est survenue lors de l\'upload');
    }
  };

  const handleFaviconUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      setError(null);
      const faviconUrl = await uploadFavicon(file);
      await updateFaviconUrl(faviconUrl);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Une erreur est survenue lors de l\'upload');
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-xl font-semibold text-gray-900">Logo Settings</h2>
          <p className="text-sm text-gray-600 mt-1">
            Manage your platform logo and favicon
          </p>
        </div>
      </div>

      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-red-700">
          <AlertCircle size={20} />
          {error}
        </div>
      )}

      <div className="space-y-8">
        {/* Logo Section */}
        <div className="space-y-6">
          {/* Current Logo Preview */}
          {settings?.logo_url && (
            <div className="p-4 bg-gray-50 rounded-lg">
              <h3 className="text-sm font-medium text-gray-700 mb-2">Current Logo</h3>
              <div className="relative w-48 h-16 bg-white rounded border border-gray-200">
                <img
                  src={settings.logo_url}
                  alt="Platform Logo"
                  className="w-full h-full object-contain p-2"
                />
              </div>
            </div>
          )}

          {/* Logo Upload */}
          <div>
            <p className="text-gray-600 mb-4">
              Upload a new logo for your platform.
              <br />
              <span className="text-sm text-gray-500">
                Maximum size: 2MB. Accepted formats: PNG, SVG
              </span>
            </p>
            <input
              type="file"
              onChange={handleLogoUpload}
              accept="image/png,image/svg+xml"
              className="hidden"
              id="logo-upload"
            />
            <label
              htmlFor="logo-upload"
              className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg transition-colors cursor-pointer ${
                uploading
                  ? 'bg-indigo-400 text-white cursor-wait'
                  : 'bg-indigo-600 text-white hover:bg-indigo-700'
              }`}
            >
              {uploading ? (
                <>
                  <Image className="animate-pulse" size={20} />
                  Uploading...
                </>
              ) : (
                <>
                  <Upload size={20} />
                  Upload New Logo
                </>
              )}
            </label>
          </div>
        </div>

        {/* Favicon Section */}
        <div className="pt-6 border-t space-y-6">
          {/* Current Favicon Preview */}
          {settings?.favicon_url && (
            <div className="p-4 bg-gray-50 rounded-lg">
              <h3 className="text-sm font-medium text-gray-700 mb-2">Current Favicon</h3>
              <div className="relative w-16 h-16 bg-white rounded border border-gray-200">
                <img
                  src={settings.favicon_url}
                  alt="Platform Favicon"
                  className="w-full h-full object-contain p-2"
                />
              </div>
            </div>
          )}

          {/* Favicon Upload */}
          <div>
            <p className="text-gray-600 mb-4">
              Upload a new favicon for your platform.
              <br />
              <span className="text-sm text-gray-500">
                Maximum size: 1MB. Accepted formats: ICO, PNG
              </span>
            </p>
            <input
              type="file"
              onChange={handleFaviconUpload}
              accept="image/x-icon,image/png"
              className="hidden"
              id="favicon-upload"
            />
            <label
              htmlFor="favicon-upload"
              className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg transition-colors cursor-pointer ${
                uploading
                  ? 'bg-indigo-400 text-white cursor-wait'
                  : 'bg-indigo-600 text-white hover:bg-indigo-700'
              }`}
            >
              {uploading ? (
                <>
                  <Image className="animate-pulse" size={20} />
                  Uploading...
                </>
              ) : (
                <>
                  <Upload size={20} />
                  Upload New Favicon
                </>
              )}
            </label>
          </div>
        </div>

        {/* Guidelines Section */}
        <div className="mt-8 p-4 bg-blue-50 rounded-lg">
          <h3 className="text-sm font-medium text-blue-900 mb-2">Upload Guidelines</h3>
          <div className="space-y-4">
            <div>
              <h4 className="text-sm font-medium text-blue-800 mb-1">Logo Guidelines</h4>
              <ul className="text-sm text-blue-800 space-y-1">
                <li>• Use PNG or SVG format for best quality</li>
                <li>• Keep the file size under 2MB</li>
                <li>• Recommended dimensions: 180x60 pixels</li>
                <li>• Use transparent background when possible</li>
              </ul>
            </div>
            <div>
              <h4 className="text-sm font-medium text-blue-800 mb-1">Favicon Guidelines</h4>
              <ul className="text-sm text-blue-800 space-y-1">
                <li>• Use ICO or PNG format</li>
                <li>• Keep the file size under 1MB</li>
                <li>• Recommended dimensions: 32x32 or 16x16 pixels</li>
                <li>• Square dimensions required</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}