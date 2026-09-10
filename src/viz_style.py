"""
viz_style.py
------------
A small, consistent visual identity for every chart in this project,
so figures look like they belong to one polished report rather than
default library output.

Usage:
    from viz_style import apply_style, PALETTE, COLORS
    apply_style()
"""

import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

# --- Brand palette -----------------------------------------------------
NAVY = "#1B2A4A"
TEAL = "#1F8A8C"
GOLD = "#D9A441"
CORAL = "#C4574A"
SLATE = "#5A6B87"
LIGHT_GREY = "#E7EAF0"
TEXT_GREY = "#3B3F45"

PALETTE = [NAVY, TEAL, GOLD, CORAL, SLATE, "#7FB3B0", "#A9764E", "#8C93A8"]

COLORS = {
    "primary": NAVY,
    "accent": GOLD,
    "positive": TEAL,
    "negative": CORAL,
    "muted": SLATE,
    "grid": LIGHT_GREY,
    "text": TEXT_GREY,
}


def apply_style():
    """Apply the project-wide matplotlib rcParams."""
    plt.rcParams.update(
        {
            "figure.facecolor": "white",
            "axes.facecolor": "white",
            "axes.edgecolor": LIGHT_GREY,
            "axes.grid": True,
            "axes.grid.axis": "y",
            "grid.color": LIGHT_GREY,
            "grid.linewidth": 0.8,
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.spines.left": False,
            "axes.titleweight": "bold",
            "axes.titlesize": 15,
            "axes.titlecolor": NAVY,
            "axes.titlepad": 14,
            "axes.labelcolor": TEXT_GREY,
            "axes.labelsize": 11,
            "xtick.color": TEXT_GREY,
            "ytick.color": TEXT_GREY,
            "xtick.labelsize": 10,
            "ytick.labelsize": 10,
            "font.family": "DejaVu Sans",
            "text.color": TEXT_GREY,
            "figure.dpi": 130,
            "savefig.dpi": 200,
            "savefig.bbox": "tight",
            "legend.frameon": False,
        }
    )


def add_titles(ax, title, subtitle=None):
    """Add a bold title plus a lighter grey subtitle above an axis (report-style).

    Places text in figure coordinates (not axes-fraction) so spacing is
    stable regardless of the axes' size, and reserves headroom via
    subplots_adjust so title/subtitle never collide with the plot area.
    """
    fig = ax.figure
    fig.subplots_adjust(top=0.80)
    pos = ax.get_position()
    fig.text(pos.x0, 0.95, title, fontsize=15, fontweight="bold", color=NAVY, ha="left", va="top")
    if subtitle:
        fig.text(pos.x0, 0.885, subtitle, fontsize=10.5, color=SLATE, ha="left", va="top")


def add_source_note(fig, text="Source: Global Electronics Retailer dataset (Maven Analytics)"):
    fig.text(0.01, -0.02, text, fontsize=8.5, color=SLATE, ha="left")


def money_formatter(decimals=1):
    """Return a matplotlib tick formatter that renders values as $ with K/M suffixes."""

    def _fmt(x, _pos):
        sign = "-" if x < 0 else ""
        x = abs(x)
        if x >= 1_000_000:
            return f"{sign}${x/1_000_000:.{decimals}f}M"
        if x >= 1_000:
            return f"{sign}${x/1_000:.{decimals}f}K"
        return f"{sign}${x:.{decimals}f}"

    return mticker.FuncFormatter(_fmt)


def pct_formatter(decimals=0):
    return mticker.FuncFormatter(lambda x, _pos: f"{x*100:.{decimals}f}%")
