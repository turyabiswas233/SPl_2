import { Button, Card, Checkbox, Flex, Link, Text } from "@radix-ui/themes";
import { MdEmail } from "react-icons/md";
import { FaKey } from "react-icons/fa";
import Input from "./Input";
import { useState } from "react";

const GoogleLoginBtn = () => {
  return (
    <div className="cursor-pointer bg-white shadow-lg shadow-gray-200/60 flex items-center justify-start gap-5 w-full p-5 pl-16 rounded-xl hover:scale-105 ease-in transition-transform">
      {/* login with google */}
      <svg
        width="36"
        height="32"
        viewBox="0 0 36 32"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M7.78827 19.2871L6.56502 23.4344L2.09406 23.5203C0.757893 21.2696 0 18.6944 0 15.9579C0 13.3117 0.708612 10.8163 1.96467 8.61902H1.96564L5.94605 9.28177L7.68971 12.875C7.32477 13.8413 7.12586 14.8786 7.12586 15.9579C7.12599 17.1293 7.35963 18.2517 7.78827 19.2871Z"
          fill="#FBBB00"
        />
        <path
          d="M34.8354 12.9767C35.0372 13.942 35.1424 14.9389 35.1424 15.9578C35.1424 17.1003 35.0101 18.2147 34.7582 19.2897C33.9028 22.9478 31.6678 26.142 28.5716 28.4024L28.5707 28.4015L23.5571 28.1692L22.8475 24.1463C24.902 23.0521 26.5076 21.3397 27.3533 19.2897H17.9576V12.9767H27.4904H34.8354Z"
          fill="#518EF8"
        />
        <path
          d="M28.5706 28.4015L28.5716 28.4024C25.5604 30.6005 21.7353 31.9157 17.5713 31.9157C10.8798 31.9157 5.06203 28.519 2.09422 23.5203L7.78844 19.2871C9.27231 22.8837 13.0926 25.4441 17.5713 25.4441C19.4964 25.4441 21.2999 24.9714 22.8475 24.1464L28.5706 28.4015Z"
          fill="#28B446"
        />
        <path
          d="M28.7869 3.67381L23.0946 7.90615C21.493 6.99692 19.5997 6.47168 17.5713 6.47168C12.9912 6.47168 9.09948 9.14943 7.68995 12.875L1.9658 8.61902H1.96484C4.8892 3.49846 10.7803 0 17.5713 0C21.8347 0 25.7438 1.37924 28.7869 3.67381Z"
          fill="#F14336"
        />
      </svg>

      <p>Login with Google</p>
    </div>
  );
};
const FacebookLoginBtn = () => {
  return (
    <div className="cursor-pointer bg-white shadow-lg shadow-gray-200/60 flex items-center justify-start gap-5 w-full p-5 pl-16 rounded-xl hover:scale-105 ease-in transition-transform">
      {/* login with google */}
      <svg
        width="16"
        height="32"
        viewBox="0 0 16 32"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M13.0789 5.31333H16V0.225333C15.496 0.156 13.7629 0 11.7444 0C2.50246 0 5.01692 10.4667 4.64895 12H0V17.688H4.64761V32H10.3458V17.6893H14.8054L15.5134 12.0013H10.3445C10.5951 8.236 9.32989 5.31333 13.0789 5.31333Z"
          fill="#3B5999"
        />
      </svg>

      <p>Login with Facebook</p>
    </div>
  );
};
function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  return (
    <div className="p-10 w-full h-dvh grid items-center">
      <header className="flex items-center justify-center flex-col gap-2">
        <p className="text-4xl poppins-medium">Welcome to</p>
        <h1
          className="poppins-black text-center text-pmv text-5xl"
          style={{
            lineHeight: "135.5%",
          }}
        >
          Dromos
        </h1>
      </header>

      <main className="flex flex-col gap-5">
        <GoogleLoginBtn />
        <FacebookLoginBtn />

        {/* hr line */}
        <div className="flex justify-center gap-2 items-center w-full">
          <span className="w-2/3 h-px border border-[#bfbfbf]"></span>
          <span>OR</span>
          <span className="w-2/3 h-px border border-[#bfbfbf]"></span>
        </div>

        <Input
          icon={<MdEmail size={30} />}
          title="Email"
          type="email"
          id="email"
          name="email"
          autoComplete="email"
          placeholder={"example@du.ac.bd"}
          required
          value={email}
          handleChange={(e) => setEmail(e.target.value)}
        />

        <Input
          icon={<FaKey size={30} />}
          title="Password"
          type="password"
          id="password"
          name="password"
          autoComplete="new-password"
          required
          value={password}
          handleChange={(e) => setPassword(e.target.value)}
        />

        <Card
          px={"4"}
          style={{
            boxShadow: "0 4px 15px #0002",
          }}
        >
          <Text as="label" size="2">
            <Flex gap="2">
              <Checkbox />
              Remember me
            </Flex>
          </Text>
        </Card>

        <button className="bg-pmv text-white poppins-semibold text-base p-3.5 rounded-lg hover:bg-scv ease-in transition-colors w-full cursor-pointer">
          Login
        </button>

        <Text as="p" size="3">
          <Link href="#" size="3">
            Forgot Password?
          </Link>
        </Text>
        <Text as="p" size="3">
          Don&rsquo;t have an account?{" "}
          <Link href="#" size="3">
            Register
          </Link>
        </Text>
      </main>
    </div>
  );
}

export default Login;
