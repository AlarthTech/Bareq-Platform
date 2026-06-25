import { cn } from "@/lib/utils";

const sizes = {
  xs: { box: "h-8 w-8", radius: "rounded-lg", ring: "ring-2", shadow: "shadow-md shadow-primary/20" },
  sm: { box: "h-11 w-11", radius: "rounded-xl", ring: "ring-2", shadow: "shadow-lg shadow-primary/25" },
  md: { box: "h-14 w-14", radius: "rounded-2xl", ring: "ring-2", shadow: "shadow-lg shadow-primary/30" },
  lg: { box: "h-[4.5rem] w-[4.5rem]", radius: "rounded-2xl", ring: "ring-[3px]", shadow: "shadow-xl shadow-primary/35" },
  xl: { box: "h-24 w-24", radius: "rounded-3xl", ring: "ring-[3px]", shadow: "shadow-2xl shadow-primary/40" },
} as const;

type LogoSize = keyof typeof sizes;

type LogoMarkProps = {
  size?: LogoSize;
  className?: string;
  showGlow?: boolean;
};

export function LogoMark({ size = "md", className, showGlow = true }: LogoMarkProps) {
  const s = sizes[size];
  const glowBlur = size === "xl" || size === "lg" ? "blur-lg" : "blur-md";

  return (
    <div className={cn("relative shrink-0", className)}>
      {showGlow && (
        <div
          className={cn(
            "pointer-events-none absolute top-[-8%] bottom-[-8%] right-[-8%] left-[22%] bg-gradient-to-br from-primary via-rose-300/90 to-primary/80 opacity-65 transition-all duration-300 group-hover:opacity-90",
            glowBlur,
            s.radius,
          )}
          aria-hidden
        />
      )}
      <div
        className={cn(
          "relative overflow-hidden ring-white/50 transition-transform duration-300 group-hover:scale-[1.03]",
          s.box,
          s.radius,
          s.ring,
          s.shadow,
        )}
      >
        <img
          src="/logo.png"
          alt="شعار البريق"
          className="h-full w-full object-cover"
          draggable={false}
        />
      </div>
    </div>
  );
}

type LogoProps = {
  size?: LogoSize;
  showText?: boolean;
  className?: string;
  textClassName?: string;
  showGlow?: boolean;
  /** للخلفيات الداكنة مثل التذييل */
  variant?: "default" | "light";
};

const textSizes: Record<LogoSize, string> = {
  xs: "text-xl",
  sm: "text-2xl",
  md: "text-3xl",
  lg: "text-[2.75rem] sm:text-[3.25rem]",
  xl: "text-5xl",
};

const gaps: Record<LogoSize, string> = {
  xs: "gap-4",
  sm: "gap-5",
  md: "gap-6",
  lg: "gap-8",
  xl: "gap-10",
};

export function Logo({
  size = "lg",
  showText = true,
  className,
  textClassName,
  showGlow = true,
  variant = "default",
}: LogoProps) {
  return (
    <div className={cn("group flex items-center overflow-visible", gaps[size], className)}>
      <LogoMark size={size} showGlow={showGlow} />
      {showText && (
        <span
          className={cn(
            "logo-wordmark shrink-0 ps-2 font-display transition-transform duration-300 group-hover:scale-[1.02]",
            variant === "light" && "logo-wordmark-light",
            textSizes[size],
            textClassName,
          )}
        >
          البريق
        </span>
      )}
    </div>
  );
}
