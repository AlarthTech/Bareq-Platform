import { Link, useLocation } from "wouter";
import { User as UserIcon, LogOut, Menu, X } from "lucide-react";
import { Logo, LogoMark } from "@/components/brand/Logo";
import { useUser, useLogout } from "@/hooks/use-auth";
import { useState } from "react";
import { Button } from "@/components/ui/button";

export function Layout({ children }: { children: React.ReactNode }) {
  const { data: user, isLoading } = useUser();
  const logout = useLogout();
  const [location] = useLocation();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const navLinks = [
    { href: "/", label: "الرئيسية" },
    ...(user ? [{ href: "/dashboard", label: "لوحة التحكم" }] : []),
  ];

  return (
    <div dir="rtl" className="min-h-screen flex flex-col bg-background font-sans text-right">
      {/* Navigation */}
      <header className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-20">
            {/* Logo */}
            <Link href="/" className="group overflow-visible">
              <Logo size="lg" />
            </Link>

            {/* Desktop Nav */}
            <nav className="hidden md:flex items-center gap-8">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`text-sm font-medium transition-colors hover:text-primary ${
                    location === link.href ? "text-primary" : "text-muted-foreground"
                  }`}
                >
                  {link.label}
                </Link>
              ))}
            </nav>

            {/* User Actions */}
            <div className="hidden md:flex items-center gap-4">
              {!isLoading && (
                user ? (
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-2 text-sm font-medium text-foreground">
                      <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center">
                        <UserIcon className="h-4 w-4 text-primary" />
                      </div>
                      <span>{user.name}</span>
                    </div>
                    <Button 
                      variant="ghost" 
                      size="sm" 
                      onClick={() => logout.mutate()}
                      disabled={logout.isPending}
                      className="text-muted-foreground hover:text-destructive"
                    >
                      <LogOut className="h-4 w-4 ms-2" />
                      خروج
                    </Button>
                  </div>
                ) : (
                  <div className="flex items-center gap-3">
                    <Link href="/login">
                      <Button variant="ghost">تسجيل الدخول</Button>
                    </Link>
                    <Link href="/register">
                      <Button className="bg-gradient-to-r from-primary to-teal-400 hover:shadow-lg hover:shadow-primary/25 transition-all">
                        حساب جديد
                      </Button>
                    </Link>
                  </div>
                )
              )}
            </div>

            {/* Mobile Menu Button */}
            <button 
              className="md:hidden p-2 text-foreground"
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            >
              {isMobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
            </button>
          </div>
        </div>

        {/* Mobile Nav */}
        {isMobileMenuOpen && (
          <div className="md:hidden border-t bg-background px-4 py-4 space-y-4 shadow-xl">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className="block text-base font-medium text-foreground hover:text-primary px-2 py-1"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                {link.label}
              </Link>
            ))}
            {!isLoading && (
              <div className="pt-4 border-t border-border flex flex-col gap-2">
                {user ? (
                  <>
                    <div className="px-2 py-2 text-sm font-medium text-muted-foreground">
                      مرحباً، {user.name}
                    </div>
                    <Button 
                      variant="outline" 
                      className="w-full justify-start"
                      onClick={() => {
                        logout.mutate();
                        setIsMobileMenuOpen(false);
                      }}
                    >
                      <LogOut className="h-4 w-4 ms-2" />
                      تسجيل الخروج
                    </Button>
                  </>
                ) : (
                  <>
                    <Link href="/login" onClick={() => setIsMobileMenuOpen(false)}>
                      <Button variant="outline" className="w-full">تسجيل الدخول</Button>
                    </Link>
                    <Link href="/register" onClick={() => setIsMobileMenuOpen(false)}>
                      <Button className="w-full">حساب جديد</Button>
                    </Link>
                  </>
                )}
              </div>
            )}
          </div>
        )}
      </header>

      {/* Main Content */}
      <main className="flex-1 w-full relative">
        {children}
      </main>

      {/* Footer */}
      <footer className="border-t bg-card mt-auto py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col md:flex-row justify-between items-center gap-6">
          <Logo size="md" showGlow={false} />
          <p className="text-muted-foreground text-sm text-center md:text-right">
            © {new Date().getFullYear()} منصة البريق لخدمات النظافة. جميع الحقوق محفوظة.
          </p>
        </div>
      </footer>
    </div>
  );
}
