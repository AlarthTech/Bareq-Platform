import { Layout } from "@/components/layout";
import { useState } from "react";
import { useLogin, useRegister } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { ArrowRight } from "lucide-react";
import { LogoMark } from "@/components/brand/Logo";
import { Link, useLocation } from "wouter";

export function Login() {
  const login = useLogin();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    login.mutate({ username, password });
  };

  return (
    <Layout>
      <div className="min-h-[80vh] flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-card p-8 rounded-3xl shadow-premium border border-border">
          <div className="text-center mb-8">
            <div className="mb-4 flex justify-center">
              <LogoMark size="xl" className="group" />
            </div>
            <h1 className="text-3xl font-display font-bold mb-2">مرحباً بعودتك</h1>
            <p className="text-muted-foreground">سجل الدخول للمتابعة في منصة البريق</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="username">اسم المستخدم</Label>
              <Input 
                id="username" 
                value={username}
                onChange={e => setUsername(e.target.value)}
                required
                className="h-12 px-4 rounded-xl text-left"
                dir="ltr"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">كلمة المرور</Label>
              <Input 
                id="password" 
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
                className="h-12 px-4 rounded-xl text-left"
                dir="ltr"
              />
            </div>
            
            <Button 
              type="submit" 
              className="w-full h-12 text-lg rounded-xl"
              disabled={login.isPending}
            >
              {login.isPending ? "جاري الدخول..." : "تسجيل الدخول"}
            </Button>
          </form>

          <p className="mt-8 text-center text-muted-foreground">
            ليس لديك حساب؟ {" "}
            <Link href="/register" className="text-primary font-bold hover:underline">
              أنشئ حساب جديد
            </Link>
          </p>
        </div>
      </div>
    </Layout>
  );
}

export function Register() {
  const register = useRegister();
  const [formData, setFormData] = useState({
    name: "",
    username: "",
    password: "",
    phone: "",
    role: "customer"
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    register.mutate(formData);
  };

  return (
    <Layout>
      <div className="min-h-[80vh] flex items-center justify-center p-4 py-12">
        <div className="w-full max-w-xl bg-card p-8 rounded-3xl shadow-premium border border-border">
          <div className="mb-8">
            <h1 className="text-3xl font-display font-bold mb-2">إنشاء حساب جديد</h1>
            <p className="text-muted-foreground">انضم إلى منصة البريق كعميل أو كشركة نظافة</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-3 bg-muted/50 p-4 rounded-2xl border border-border">
              <Label className="text-base">نوع الحساب</Label>
              <RadioGroup 
                defaultValue="customer" 
                onValueChange={(val) => setFormData({...formData, role: val})}
                className="flex gap-4"
              >
                <div className="flex items-center space-x-2 space-x-reverse bg-card px-4 py-3 rounded-xl border flex-1 cursor-pointer hover:border-primary transition-colors">
                  <RadioGroupItem value="customer" id="r1" />
                  <Label htmlFor="r1" className="cursor-pointer font-medium flex-1">عميل (أبحث عن خدمة)</Label>
                </div>
                <div className="flex items-center space-x-2 space-x-reverse bg-card px-4 py-3 rounded-xl border flex-1 cursor-pointer hover:border-primary transition-colors">
                  <RadioGroupItem value="company" id="r2" />
                  <Label htmlFor="r2" className="cursor-pointer font-medium flex-1">شركة نظافة (مقدم خدمة)</Label>
                </div>
              </RadioGroup>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <Label htmlFor="name">الاسم الكامل / اسم الشركة</Label>
                <Input 
                  id="name" 
                  value={formData.name}
                  onChange={e => setFormData({...formData, name: e.target.value})}
                  required
                  className="h-12 px-4 rounded-xl"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="phone">رقم الهاتف</Label>
                <Input 
                  id="phone" 
                  value={formData.phone}
                  onChange={e => setFormData({...formData, phone: e.target.value})}
                  className="h-12 px-4 rounded-xl text-left"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="username">اسم المستخدم (للدخول)</Label>
                <Input 
                  id="username" 
                  value={formData.username}
                  onChange={e => setFormData({...formData, username: e.target.value})}
                  required
                  className="h-12 px-4 rounded-xl text-left"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="password">كلمة المرور</Label>
                <Input 
                  id="password" 
                  type="password"
                  value={formData.password}
                  onChange={e => setFormData({...formData, password: e.target.value})}
                  required
                  className="h-12 px-4 rounded-xl text-left"
                  dir="ltr"
                />
              </div>
            </div>
            
            <Button 
              type="submit" 
              className="w-full h-12 text-lg rounded-xl mt-4"
              disabled={register.isPending}
            >
              {register.isPending ? "جاري الإنشاء..." : "إنشاء الحساب"}
            </Button>
          </form>

          <p className="mt-8 text-center text-muted-foreground">
            لديك حساب بالفعل؟ {" "}
            <Link href="/login" className="text-primary font-bold hover:underline">
              تسجيل الدخول
            </Link>
          </p>
        </div>
      </div>
    </Layout>
  );
}
