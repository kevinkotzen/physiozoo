function [] = plot_hrv_freq_spectrum( ax, plot_data, varargin )
%PLOT_HRV_FREQ_SPECTRUM Plots the spectrums generated by hrv_freq.
%   ax: axes handle to plot to.
%   plot_data: struct returned from hrv_freq.
%

%% Input
p = inputParser;
p.addRequired('ax', @(x) isgraphics(x, 'axes'));
p.addRequired('plot_data', @isstruct);
p.addParameter('clear', false, @islogical);
p.addParameter('tag', default_axes_tag(mfilename), @ischar);
p.addParameter('ylim', 'auto');
p.addParameter('peaks', false);
p.addParameter('detailed_legend', true);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
yrange = p.Results.ylim;
plot_peaks = p.Results.peaks;
detailed_legend = p.Results.detailed_legend;

f_axis          = plot_data.f_axis;
pxx_lomb        = plot_data.pxx_lomb;
pxx_ar          = plot_data.pxx_ar;
pxx_welch       = plot_data.pxx_welch;
pxx_fft         = plot_data.pxx_fft;
vlf_band        = plot_data.vlf_band;
lf_band         = plot_data.lf_band;
hf_band         = plot_data.hf_band;
f_max           = plot_data.f_max;
t_win           = plot_data.t_win;
welch_overlap   = plot_data.welch_overlap;
ar_order        = plot_data.ar_order;
num_windows     = plot_data.num_windows;
lf_peak         = plot_data.lf_peaks(1);
hf_peak         = plot_data.hf_peaks(1);

%% Plot
if clear
    cla(ax);
end

legend_entries = {};

% Spectra
if ~isempty(pxx_lomb)
    semilogy(f_axis, pxx_lomb, 'Parent', ax); grid(ax, 'on'); hold(ax, 'on');
    if detailed_legend
        legend_entries{end+1} = sprintf('Lomb (t_{win}=%.1fm, n_{win}=%d)', t_win/60, num_windows);
    else
        legend_entries{end+1} = 'Lomb';
    end
end
if ~isempty(pxx_ar)
    semilogy(f_axis, pxx_ar, 'Parent', ax); grid(ax, 'on'); hold(ax, 'on');
    if detailed_legend
        legend_entries{end+1} = sprintf('AR (order=%d)', ar_order);
    else
        legend_entries{end+1} = 'AR';
    end
end
if ~isempty(pxx_welch)
    semilogy(f_axis, pxx_welch, 'Parent', ax); grid(ax, 'on'); hold(ax, 'on');
    if detailed_legend
        legend_entries{end+1} = sprintf('Welch (t_{win}=%.1fm, %d%% ovl.)', t_win/60, welch_overlap);
    else
        legend_entries{end+1} = 'Welch';
    end
end
if ~isempty(pxx_fft)
    semilogy(f_axis, pxx_fft, 'Parent', ax); grid(ax, 'on'); hold(ax, 'on');
    if detailed_legend
        legend_entries{end+1} = sprintf('FFT (twin=%.1fm, nwin=%d)', t_win/60, num_windows);
    else
        legend_entries{end+1} = 'FFT';
    end
end

% Peaks
if plot_peaks && ~isnan(lf_peak)
    plot(ax, lf_peak, pxx_lomb(f_axis==lf_peak).*1.25, 'bv', 'MarkerSize', 8, 'MarkerFaceColor', 'blue');
    legend_entries{end+1} = sprintf('%.3f Hz', lf_peak);
end
if plot_peaks && ~isnan(hf_peak)
    plot(ax, hf_peak, pxx_lomb(f_axis==hf_peak).*1.25, 'rv', 'MarkerSize', 8, 'MarkerFaceColor', 'red');
    legend_entries{end+1} = sprintf('%.3f Hz', hf_peak);
end

% Axes limits
xrange = [0,f_max*1.01];
xlim(ax, xrange);
ylim(ax, yrange);
yrange = ylim(ax); % in case it was 'auto'

% Vertical lines of frequency ranges
lw = 3; ls = ':'; lc = 'black';
line(vlf_band(1) * ones(1,2), yrange, 'Parent', ax, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
line(lf_band(1)  * ones(1,2), yrange, 'Parent', ax, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
line(hf_band(1)  * ones(1,2), yrange, 'Parent', ax, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
line(hf_band(2)  * ones(1,2), yrange, 'Parent', ax, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);

% Names of frequency ranges
text(vlf_band(1), yrange(2) * 0.5, ' VLF', 'Parent', ax);
text( lf_band(1), yrange(2) * 0.5,  ' LF', 'Parent', ax);
text( hf_band(1), yrange(2) * 0.5,  ' HF', 'Parent', ax);

% Labels
legend(ax, legend_entries);
xlabel(ax, 'Frequency [Hz]');
ylabel(ax, 'Log Power Density [s^2/Hz]');

%% Tag
ax.Tag = tag;

end
